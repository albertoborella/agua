import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agua/features/auth/providers/auth_provider.dart';
import 'package:agua/shared/services/api_service.dart';

const String _baseUrl = 'https://api.example.invalid';
const String _tenantId = 'demo';
const String _refreshToken = 'refresh-token';

/// A decodable JWT, because `AuthProvider` reads the user out of the payload:
/// an opaque token would leave the provider unauthenticated and the test would
/// not be exercising a real login.
final String _accessToken = _jwt(<String, Object?>{
  'sub': 'user-1',
  'tenant': _tenantId,
  'rol': 'ADMIN',
});

String _jwt(Map<String, Object?> payload) {
  String segment(Map<String, Object?> value) => base64Url
      .encode(utf8.encode(json.encode(value)))
      .replaceAll('=', '');

  return '${segment(<String, Object?>{'alg': 'HS256', 'typ': 'JWT'})}'
      '.${segment(payload)}'
      '.signature';
}

/// A fake backend that records every outbound request before answering it.
///
/// `http.runWithClient` installs the client for the whole zone, so the top-level
/// `http.get` inside `ApiService.getAnalysisTypes()` lands here: the recorded
/// [http.Request] is the real one, built with the same headers and URL the app
/// would put on the wire.
class _FakeBackend {
  final List<http.Request> requests = <http.Request>[];

  http.Client get client => MockClient((http.Request request) async {
        requests.add(request);
        return http.Response(
          json.encode(_bodyFor(request.url.path)),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

  Object? _bodyFor(String path) => path == '/auth/login'
      ? <String, Object?>{
          'access_token': _accessToken,
          'refresh_token': _refreshToken,
        }
      : <Object?>[];

  /// The one request matching `method` + `path`, so an assertion can never read
  /// a header off a different call.
  http.Request only(String method, String path) {
    final matches = requests
        .where((r) => r.method == method && r.url.path == path)
        .toList();
    expect(matches, hasLength(1), reason: 'expected exactly one $method $path');
    return matches.single;
  }
}

/// Answers `login()` without touching the in-memory token state.
///
/// The real `ApiService.login()` happens to call `setTokens` itself, so a test
/// built on it cannot tell WHO hydrated the client. Overriding only `login()`
/// isolates `AuthProvider`'s own responsibility: the only thing that can put a
/// token on this instance is `AuthProvider.login()` calling `setTokens`.
class _ApiServiceWithoutLoginSideEffects extends ApiService {
  _ApiServiceWithoutLoginSideEffects() : super(baseUrl: _baseUrl);

  @override
  Future<Map<String, dynamic>> login(
          String username, String password, String tenantId) async =>
      <String, dynamic>{
        'access_token': _accessToken,
        'refresh_token': _refreshToken,
      };
}

/// Regression tests for the missing `Authorization` header after `login()`.
///
/// `AuthProvider.login()` persisted the tokens to `SharedPreferences` and
/// returned `true`, but it never called `api.setTokens(...)`, so the in-memory
/// `ApiService` kept a null access token and `_headers` silently omitted
/// `Authorization`. Login itself still succeeded -- it is the first screen that
/// needs data that failed, with `Exception: Error al obtener tipos de análisis`,
/// which is why the only cure was reloading the page to trigger `init()`.
///
/// The tests assert on the outbound request, not on the internals: there is no
/// public getter for the token, and the header is the whole point.
void main() {
  // The tenant id is a persistent setting: `AuthProvider` reads it in `init()`,
  // and `login()` bails out before ever reaching the API without it.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tenant_id': _tenantId,
    });
  });

  test('login() hydrates the ApiService, so the next request sends the bearer token',
      () async {
    final backend = _FakeBackend();
    final api = _ApiServiceWithoutLoginSideEffects();
    final auth = AuthProvider(api: api);

    await http.runWithClient(() async {
      await auth.init();
      expect(await auth.login('operario', 'secreto'), isTrue,
          reason: 'login is expected to succeed');
      expect(auth.isAuthenticated, isTrue,
          reason: 'the JWT decoded into a user, so this is a real session');

      // The real implementation on purpose: this is the call that used to go
      // out with no `Authorization` header and come back 401.
      await api.getAnalysisTypes();
    }, () => backend.client);

    expect(
      backend.only('GET', '/catalog/analysis-types').headers['Authorization'],
      'Bearer $_accessToken',
      reason: 'the token returned by login must be on the next authenticated call',
    );
  });

  test('the production ApiService sends the same header on the first screen load',
      () async {
    final backend = _FakeBackend();
    final api = ApiService(baseUrl: _baseUrl);
    final auth = AuthProvider(api: api);

    await http.runWithClient(() async {
      await auth.init();
      expect(await auth.login('operario', 'secreto'), isTrue);

      await api.getAnalysisTypes();
    }, () => backend.client);

    expect(backend.only('POST', '/auth/login').headers.containsKey('Authorization'),
        isFalse,
        reason: 'the login call itself is unauthenticated');
    expect(
      backend.only('GET', '/catalog/analysis-types').headers['Authorization'],
      'Bearer $_accessToken',
    );
  });
}
