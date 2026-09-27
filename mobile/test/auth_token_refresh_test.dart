import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agua/features/auth/providers/auth_provider.dart';
import 'package:agua/shared/services/api_service.dart';

const String _baseUrl = 'https://api.example.invalid';
const String _tenantId = 'demo';
const String _storedRefreshToken = 'stored-refresh-token';

const String _storedUserJson =
    '{"id":"1","tenant_id":"demo","username":"operario",'
    '"email":"op@demo.com","rol":"OPERARIO","activo":true,'
    '"created_at":"2026-01-01T00:00:00"}';

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

String _jwt(Map<String, Object?> payload) {
  String segment(Map<String, Object?> value) => base64Url
      .encode(utf8.encode(json.encode(value)))
      .replaceAll('=', '');

  return '${segment(<String, Object?>{'alg': 'HS256', 'typ': 'JWT'})}'
      '.${segment(payload)}'
      '.signature';
}

/// An access token whose `exp` sits [lifetime] from now.
///
/// Minted in the fake layer rather than against the live backend on purpose:
/// the test needs to be the sole authority on whether a token is expired, and
/// `exp` is the only thing `AuthProvider` is allowed to look at.
String _accessTokenExpiringIn(Duration lifetime) => _jwt(<String, Object?>{
      'sub': '1',
      'tenant': _tenantId,
      'rol': 'OPERARIO',
      'iat': _nowSeconds - 1900,
      'exp': _nowSeconds + lifetime.inSeconds,
    });

/// An access token that is already dead: it died 1 second ago, well past the
/// clock-skew allowance, so no tolerance can explain the 401 away.
String get _staleAccessToken =>
    _accessTokenExpiringIn(const Duration(seconds: -1));

/// What the backend hands back from `/auth/refresh`.
String get _renewedAccessToken =>
    _accessTokenExpiringIn(const Duration(minutes: 30));

const String _renewedRefreshToken = 'renewed-refresh-token';

/// The cold-start deadline the tests below inject instead of waiting out
/// [AuthProvider.renewalTimeout].
///
/// Production always uses the documented default; this only exists so the
/// deadline can be proven in milliseconds instead of ten seconds. It is nowhere
/// near the default on purpose: if the fake's answer and the deadline were the
/// same distance apart, a slow CI box could flip which one wins and the test
/// would be a coin toss.
const Duration _fastRenewalTimeout = Duration(milliseconds: 300);

http.Response _json(Object? body, int statusCode) => http.Response(
      json.encode(body),
      statusCode,
      headers: <String, String>{'content-type': 'application/json'},
    );

/// A fake backend that records every outbound request before answering it.
///
/// `http.runWithClient` installs the client for the whole zone, so the top-level
/// `http.get`/`http.post` inside `ApiService` land here. The recorded
/// [http.Request] is the real one, built with the same headers and URL the app
/// would put on the wire, which is the only place the bearer token is visible.
class _FakeBackend {
  _FakeBackend(this.handler);

  final Future<http.Response> Function(http.Request request) handler;
  final List<http.Request> requests = <http.Request>[];

  http.Client get client => MockClient((http.Request request) {
        requests.add(request);
        return handler(request);
      });

  int countOf(String method, String path) => requests
      .where((r) => r.method == method && r.url.path == path)
      .length;

  /// Every request matching `method` + `path`, oldest first.
  List<http.Request> all(String method, String path) => requests
      .where((r) => r.method == method && r.url.path == path)
      .toList(growable: false);

  /// The one request matching `method` + `path`, so an assertion can never read
  /// a header off a different call.
  http.Request only(String method, String path) {
    final matches = all(method, path);
    expect(matches, hasLength(1), reason: 'expected exactly one $method $path');
    return matches.single;
  }
}

/// Answer `POST /auth/refresh` with a valid renewal, everything else 401.
///
/// This is the "the refresh itself worked but the token is still rejected"
/// shape, which is the worst case: a naive retry loop would spin forever.
_FakeBackend _refreshOkButAccessStillRejected() => _FakeBackend(
      (http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          return _json(<String, Object?>{
            'access_token': _renewedAccessToken,
            'refresh_token': _renewedRefreshToken,
          }, 200);
        }
        return _json(<String, Object?>{'detail': 'Token expirado'}, 401);
      },
    );

void main() {
  group('cold start (AuthProvider.init)', () {
    test('renews an expired access token instead of dropping the user at login',
        () async {
      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          return _json(<String, Object?>{
            'access_token': _renewedAccessToken,
            'refresh_token': _renewedRefreshToken,
          }, 200);
        }
        return _json(<Object?>[], 200);
      });

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': _staleAccessToken,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(api: ApiService(baseUrl: _baseUrl));
      await http.runWithClient(auth.init, () => backend.client);

      expect(backend.countOf('POST', '/auth/refresh'), 1,
          reason: 'a renewable session must not send the user to the login screen');
      expect(
        json.decode(backend.only('POST', '/auth/refresh').body)['refresh_token'],
        _storedRefreshToken,
        reason: 'the renewal must use the refresh token that was on disk',
      );
      expect(auth.isInitialized, isTrue);
      expect(auth.isAuthenticated, isTrue,
          reason: 'the session was still renewable, so the user stays signed in');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), _renewedAccessToken,
          reason: 'the new access token must be persisted for the next cold start');
      expect(prefs.getString('refresh_token'), _renewedRefreshToken);
      expect(prefs.getString('user_json'), _storedUserJson);

      // ...and the renewed token, not the dead one, is what goes on the wire.
      await http.runWithClient(
          () => auth.api.getSampleSources(), () => backend.client);
      expect(
        backend.only('GET', '/samples/sources').headers['Authorization'],
        'Bearer $_renewedAccessToken',
      );
    });

    test('falls back to the login screen and wipes storage when the refresh is rejected',
        () async {
      final backend = _FakeBackend(
          (http.Request request) async => _json(<String, Object?>{'detail': 'refresh revocado'}, 401));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': _staleAccessToken,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(api: ApiService(baseUrl: _baseUrl));
      await http.runWithClient(auth.init, () => backend.client);

      expect(backend.countOf('POST', '/auth/refresh'), 1,
          reason: 'one attempt only: a dead refresh token must not be retried in a loop');
      expect(auth.isInitialized, isTrue,
          reason: 'the splash must still lift, otherwise the user stares at it forever');
      expect(auth.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
      expect(prefs.getString('user_json'), isNull);
      expect(prefs.getString('tenant_id'), _tenantId,
          reason: 'tenant_id is a persistent setting and must survive a failed restore');
    });

    test('does not hit /auth/refresh at all when the stored token is still valid',
        () async {
      final backend = _FakeBackend((http.Request request) async => _json(<Object?>[], 200));

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': _accessTokenExpiringIn(const Duration(minutes: 30)),
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(api: ApiService(baseUrl: _baseUrl));
      await http.runWithClient(auth.init, () => backend.client);

      expect(backend.requests, isEmpty,
          reason: 'a live token must not cost a network round trip on every cold start');
      expect(auth.isAuthenticated, isTrue);
    });

    test('restores the stored session and renders when the renewal never answers',
        () async {
      // A captive portal, a backend that is not up yet, a closed laptop lid:
      // from the app's side they are all the same thing -- the request goes out
      // and no response ever comes back. `neverAnswers` is deliberately never
      // completed, so nothing in this test can unstick a cold start that waits
      // on it forever. That is the point: `main.dart` holds the first frame
      // behind `init()`, so an unbounded renewal is a blank screen, forever.
      final neverAnswers = Completer<http.Response>();
      final stale = _staleAccessToken;

      var renewalHangs = true;
      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          if (renewalHangs) return neverAnswers.future;
          return _json(<String, Object?>{
            'access_token': _renewedAccessToken,
            'refresh_token': _renewedRefreshToken,
          }, 200);
        }
        if (request.headers['Authorization'] == 'Bearer $stale') {
          return _json(<String, Object?>{'detail': 'Token expirado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': stale,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(
        api: ApiService(baseUrl: _baseUrl),
        renewalTimeout: _fastRenewalTimeout,
      );

      // The bound is what turns "waited forever" into a failing test instead of
      // a hanging suite: the fake cannot answer, so no correct implementation
      // can outlast it.
      await http.runWithClient(auth.init, () => backend.client)
          .timeout(const Duration(seconds: 10));

      expect(backend.countOf('POST', '/auth/refresh'), 1,
          reason: 'one attempt, then the deadline gives up on it');
      expect(auth.isInitialized, isTrue,
          reason: 'the splash must lift: a blank screen is worse than any 401');
      expect(auth.isAuthenticated, isTrue,
          reason: 'a timeout says nothing about the refresh token, so nobody is signed out');
      expect(auth.error, isNull,
          reason: 'a silent restore must not greet the user with an error');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), stale,
          reason: 'nothing new was learned about the session, so nothing is written');
      expect(prefs.getString('refresh_token'), _storedRefreshToken,
          reason: 'never discard a 7 day refresh token because the network blinked');
      expect(prefs.getString('user_json'), _storedUserJson);
      expect(prefs.getString('tenant_id'), _tenantId);

      // The optimism is only safe because the 401 path is still armed, and that
      // is the whole argument for restoring instead of signing out: the first
      // real request goes out with the stale token, is refused, and is renewed
      // and replayed -- with no login screen in between.
      renewalHangs = false;
      final sources = await http.runWithClient(
          () => auth.api.getSampleSources(), () => backend.client);

      expect(sources, isEmpty);
      final attempts = backend.all('GET', '/samples/sources');
      expect(attempts, hasLength(2),
          reason: 'one attempt, one replay: the backstop has to actually fire');
      expect(attempts.first.headers['Authorization'], 'Bearer $stale',
          reason: 'the first request goes out with the restored session');
      expect(attempts.last.headers['Authorization'], 'Bearer $_renewedAccessToken',
          reason: 'and the replay carries the token the renewal produced');
      expect(auth.isAuthenticated, isTrue);
    });

    test('keeps the stored session when the renewal never reached a server', () async {
      // The sibling of the timeout above, and the shape the
      // `on http.ClientException` clause exists for. `IOClient` raises exactly
      // this type for a refused connection, an unresolvable host or a TLS
      // handshake that dies mid-flight: the request left the device and no
      // server ever got the chance to judge the token. That is silence about
      // the network, not a verdict on a refresh token that is good for seven
      // days, so the stored session has to survive it untouched.
      //
      // Before the clause this shape reached `init()`'s catch, which called
      // `_forgetStoredSession()`: the user lost a working token and had to log
      // in again, purely because the backend was not up yet.
      final stale = _staleAccessToken;

      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          throw http.ClientException(
              'Connection refused', Uri.parse('$_baseUrl/auth/refresh'));
        }
        return _json(<Object?>[], 200);
      });

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': stale,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(
        api: ApiService(baseUrl: _baseUrl),
        // A deadline this far out cannot be what saved the session. The fake
        // fails immediately, so the deadline never comes into play and the only
        // thing standing between a wiped refresh token and these assertions is
        // the exception clause -- the deadline has its own test above.
        renewalTimeout: const Duration(minutes: 5),
      );

      // The bound is a harness guard, not the mechanism: a correct build
      // returns in microseconds, and so does a build that swallows nothing and
      // takes the destructive path instead. Both are fast, so the bound never
      // decides the outcome.
      await http.runWithClient(auth.init, () => backend.client)
          .timeout(const Duration(seconds: 10));

      expect(backend.countOf('POST', '/auth/refresh'), 1,
          reason: 'the renewal has to actually be attempted -- otherwise "storage '
              'intact" would only be proving the token was never expired');
      expect(
        json.decode(backend.only('POST', '/auth/refresh').body)['refresh_token'],
        _storedRefreshToken,
        reason: 'the attempt must carry the refresh token that was on disk',
      );

      expect(auth.isInitialized, isTrue,
          reason: 'the splash must still lift: a blank screen is worse than a 401');
      expect(auth.isAuthenticated, isTrue,
          reason: 'nobody answered, so nothing has said the session is over');
      expect(auth.user?.username, 'operario',
          reason: 'the restored user is the point of restoring at all');
      expect(auth.error, isNull,
          reason: 'a silent restore must not greet the user with an error');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), stale,
          reason: 'nothing new was learned, so the stored token is left byte for byte');
      expect(prefs.getString('refresh_token'), _storedRefreshToken,
          reason: 'never discard a 7 day refresh token because the backend was down');
      expect(prefs.getString('user_json'), _storedUserJson);
      expect(prefs.getString('tenant_id'), _tenantId);

      // The in-memory session survived too, not just the bytes on disk. The
      // bearer header is the only place the live token is observable, and a
      // `clearTokens()` that ran without the storage wipe would slip past every
      // assertion above.
      await http.runWithClient(
          () => auth.api.getSampleSources(), () => backend.client);
      expect(
        backend.only('GET', '/samples/sources').headers['Authorization'],
        'Bearer $stale',
        reason: 'the restored session must still be the one that goes on the wire',
      );
    });

    test('discards a refresh token the server actively rejected', () async {
      // The other half of the boundary. Here the backend DID answer and what it
      // said was no. No amount of retrying turns that into a yes, so the stored
      // session has to go: the app cannot tell a dead session from a live one
      // on the next cold start, and keeping the bytes would walk the user back
      // into the same dead end with no way out but a fresh login that never
      // looks necessary.
      //
      // This is also what keeps the `on http.ClientException` clause honest. The
      // rejection arrives from `ApiService.refreshToken()` as a plain
      // `Exception('Token inválido')`, NOT as a `ClientException`, so widening
      // that clause into a blanket `catch (_)` would swallow the server's
      // verdict along with the network failures and restore a session the
      // backend has already refused. These assertions are what go red then.
      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          return _json(<String, Object?>{'detail': 'refresh revocado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': _staleAccessToken,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(api: ApiService(baseUrl: _baseUrl));
      await http.runWithClient(auth.init, () => backend.client);

      expect(backend.countOf('POST', '/auth/refresh'), 1,
          reason: 'one answer is a verdict: asking again cannot un-refuse a token');
      expect(auth.isInitialized, isTrue,
          reason: 'the splash must still lift even when the session is dead');
      expect(auth.isAuthenticated, isFalse,
          reason: 'the server said no, so the login screen is the only honest state');
      expect(auth.user, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull,
          reason: 'the token the backend refused must not be left behind to fail again');
      expect(prefs.getString('user_json'), isNull);
      expect(prefs.getString('tenant_id'), _tenantId,
          reason: 'tenant_id is a persistent setting and must survive a failed restore');

      // ...and the in-memory session went with it. Wiping only the storage would
      // let a request leave the device carrying a token nobody will accept.
      await http.runWithClient(
          () => auth.api.getSampleSources(), () => backend.client);
      expect(
        backend.only('GET', '/samples/sources').headers.containsKey('Authorization'),
        isFalse,
        reason: 'a rejected session has to be cleared in memory, not only on disk',
      );
    });

    test('separates the two shapes by failure type, not by how the start felt',
        () async {
      // The two cases above are the same symptom to a user -- a cold start that
      // ends somewhere -- with opposite storage outcomes, and the ONLY thing
      // that tells them apart is the type of failure. Pin that directly instead
      // of leaving it implied by the storage assertions, because it is the fact
      // the whole clause rests on: collapse the types and the two outcomes
      // collapse together.
      final unreachable = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          throw http.ClientException(
              'Failed host lookup: api.example.invalid',
              Uri.parse('$_baseUrl/auth/refresh'));
        }
        return _json(<Object?>[], 200);
      });

      final refused = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          return _json(<String, Object?>{'detail': 'refresh revocado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      Future<({bool authenticated, String? refreshToken})> coldStart(
          _FakeBackend backend) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'tenant_id': _tenantId,
          'access_token': _staleAccessToken,
          'refresh_token': _storedRefreshToken,
          'user_json': _storedUserJson,
        });
        final auth = AuthProvider(
          api: ApiService(baseUrl: _baseUrl),
          // Far enough out that the deadline cannot explain either outcome.
          renewalTimeout: const Duration(minutes: 5),
        );
        await http.runWithClient(auth.init, () => backend.client)
            .timeout(const Duration(seconds: 10));
        expect(backend.countOf('POST', '/auth/refresh'), 1,
            reason: 'the renewal must be attempted, or the outcome below is vacuous');
        final prefs = await SharedPreferences.getInstance();
        return (
          authenticated: auth.isAuthenticated,
          refreshToken: prefs.getString('refresh_token'),
        );
      }

      final afterUnreachable = await coldStart(unreachable);
      final afterRefused = await coldStart(refused);

      expect(afterUnreachable.refreshToken, _storedRefreshToken,
          reason: 'a renewal that never landed is not evidence against the token');
      expect(afterUnreachable.authenticated, isTrue);
      expect(afterRefused.refreshToken, isNull,
          reason: 'a renewal that was refused is evidence against the token');
      expect(afterRefused.authenticated, isFalse,
          reason: 'identical shape, opposite verdict -- that is the boundary');

      // And the reason the clause can be that narrow: the transport failure
      // stays recognisable as a transport failure, and the server verdict stays
      // recognisable as a verdict. A `catch (_)` cannot tell them apart, which
      // is precisely what must not happen.
      final probe = ApiService(baseUrl: _baseUrl)
        ..setTokens(_staleAccessToken, _storedRefreshToken, _tenantId);

      await expectLater(
        http.runWithClient(probe.refreshToken, () => unreachable.client),
        throwsA(isA<http.ClientException>()),
        reason: 'never-reached-the-server has to stay typed as never-reached',
      );
      await expectLater(
        http.runWithClient(probe.refreshToken, () => refused.client),
        throwsA(allOf(isA<Exception>(), isNot(isA<http.ClientException>()))),
        reason: 'the server answered no, and that must not be mistakable for a '
            'network problem or the clause is a guess',
      );
    });

    test('a rejection that answers late but inside the deadline is still a dead session',
        () async {
      // The narrowness guard. The deadline may swallow a renewal that never
      // answers, and only that: a renewal that answers -- even late -- has
      // something to say, and a 401 is the backend stating that the refresh
      // token is gone. A deadline implemented as a blanket catch would hide
      // that answer here and restore a session nobody can use.
      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _json(<String, Object?>{'detail': 'refresh revocado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': _tenantId,
        'access_token': _staleAccessToken,
        'refresh_token': _storedRefreshToken,
        'user_json': _storedUserJson,
      });

      final auth = AuthProvider(
        api: ApiService(baseUrl: _baseUrl),
        renewalTimeout: _fastRenewalTimeout,
      );
      await http.runWithClient(auth.init, () => backend.client);

      expect(auth.isInitialized, isTrue);
      expect(auth.isAuthenticated, isFalse,
          reason: 'a refused refresh token is dead, and dead still means the login screen');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
      expect(prefs.getString('user_json'), isNull);
      expect(prefs.getString('tenant_id'), _tenantId,
          reason: 'tenant_id is a persistent setting and must survive a failed restore');
    });
  });

  group('mid-session (ApiService)', () {
    test('refreshes once and retries the 401 request with the new token', () async {
      final stale = _staleAccessToken;
      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          return _json(<String, Object?>{
            'access_token': _renewedAccessToken,
            'refresh_token': _renewedRefreshToken,
          }, 200);
        }
        if (request.headers['Authorization'] == 'Bearer $stale') {
          return _json(<String, Object?>{'detail': 'Token expirado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      final api = ApiService(baseUrl: _baseUrl);
      api.setTokens(stale, _storedRefreshToken, _tenantId);

      final sources = await http.runWithClient(
          () => api.getSampleSources(), () => backend.client);

      expect(sources, isEmpty);
      expect(backend.countOf('POST', '/auth/refresh'), 1);

      final attempts = backend.all('GET', '/samples/sources');
      expect(attempts, hasLength(2), reason: 'one attempt, one retry: never more');
      expect(attempts[0].headers['Authorization'], 'Bearer $stale');
      expect(attempts[1].headers['Authorization'], 'Bearer $_renewedAccessToken',
          reason: 'the retry must carry the token the refresh produced');
    });

    test('gives up with the user-facing error when the retry 401s as well', () async {
      final backend = _refreshOkButAccessStillRejected();

      final api = ApiService(baseUrl: _baseUrl);
      api.setTokens(_staleAccessToken, _storedRefreshToken, _tenantId);

      await expectLater(
        http.runWithClient(
            () => api.getAnalysisTypes(), () => backend.client),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error al obtener tipos de análisis'),
        )),
      );

      expect(backend.countOf('GET', '/catalog/analysis-types'), 2,
          reason: 'exactly one retry: a token the backend keeps rejecting must not loop');
      expect(backend.countOf('POST', '/auth/refresh'), 1);
    });

    test('concurrent 401s share a single in-flight refresh', () async {
      final stale = _staleAccessToken;

      // Hold the renewal open until every request has already been rejected.
      // Without a single-flight guard each of the N callers starts its own
      // refresh, so a single screen full of stale-token requests would spend N
      // round trips on the renewal instead of one.
      final refreshGate = Completer<void>();
      final allRejected = Completer<void>();
      var rejected = 0;

      final backend = _FakeBackend((http.Request request) async {
        if (request.url.path == '/auth/refresh') {
          await refreshGate.future;
          return _json(<String, Object?>{
            'access_token': _renewedAccessToken,
            'refresh_token': _renewedRefreshToken,
          }, 200);
        }
        if (request.headers['Authorization'] == 'Bearer $stale') {
          rejected++;
          if (rejected == 5) allRejected.complete();
          return _json(<String, Object?>{'detail': 'Token expirado'}, 401);
        }
        return _json(<Object?>[], 200);
      });

      final api = ApiService(baseUrl: _baseUrl);
      api.setTokens(stale, _storedRefreshToken, _tenantId);

      await http.runWithClient(() async {
        final inFlight =
            List.generate(5, (_) => api.getSampleSources());

        await allRejected.future;
        // The last rejection is recorded before the call that received it
        // resumes, so let every caller reach the renewal before counting: the
        // point is to catch a stampede while all of them are still waiting.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(backend.countOf('POST', '/auth/refresh'), 1,
            reason: 'a burst of 401s must not stampede the refresh endpoint');

        refreshGate.complete();
        await Future.wait(inFlight);
      }, () => backend.client);

      expect(backend.countOf('POST', '/auth/refresh'), 1);
      expect(backend.all('GET', '/samples/sources'), hasLength(10),
          reason: '5 rejected + 5 retried, so nobody was left hanging');
      expect(
        backend
            .all('GET', '/samples/sources')
            .map((r) => r.headers['Authorization'])
            .where((h) => h == 'Bearer $_renewedAccessToken'),
        hasLength(5),
        reason: 'every waiter must resume with the token the shared refresh produced',
      );
    });
  });
}
