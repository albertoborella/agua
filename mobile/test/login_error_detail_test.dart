import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agua/features/auth/providers/auth_provider.dart';
import 'package:agua/shared/services/api_service.dart';

const String _baseUrl = 'https://api.example.invalid';

/// The exact `detail` the backend answers with for a company id that is not
/// provisioned. Verbatim from `POST /auth/login` on an unknown tenant:
/// `{"detail":"El ID de empresa no está registrado ..."}`, 404.
const String _unknownCompanyDetail =
    'El ID de empresa no está registrado o no tiene usuarios configurados. '
    'Verificá el ID e intentá de nuevo.';

/// What the user used to read for a wrong company id: told the password was
/// wrong when the id was the problem.
const String _genericLoginMessage = 'Credenciales inválidas';

/// A backend that answers the login call with [status] and [body].
///
/// [body] is a String on purpose. A test can then hand the client a real HTTP
/// payload -- `{"detail": "..."}`, an HTML page from a proxy, nothing at all --
/// without this helper deciding what that payload should have been.
http.Client _answering(int status, String body,
        {String contentType = 'application/json'}) =>
    MockClient((http.Request request) async => http.Response(body, status,
        headers: <String, String>{'content-type': contentType}));

/// What the user actually reads.
///
/// `AuthProvider.login()` does `e.toString().replaceAll('Exception: ', '')` and
/// the login screen paints `auth.error` as-is, so the string under test is the
/// one that reaches the screen, not the exception's own `toString()`. Asserting
/// on the raw `toString()` would pass even for a message that arrives at the
/// user with a stray `Exception: ` glued to the front.
String _shownToUser(Object thrown) =>
    thrown.toString().replaceAll('Exception: ', '');

/// Runs a real `login()` against a backend answering [status]/[body] and
/// returns what it threw.
Future<Object> _loginAgainst(int status, String body,
    {String contentType = 'application/json'}) async {
  Object? thrown;
  final api = ApiService(baseUrl: _baseUrl);
  await http.runWithClient(() async {
    try {
      await api.login('operario', 'secreto', 'empresa-inexistente');
      fail('login() should have thrown on a $status');
    } catch (e) {
      thrown = e;
    }
  }, () => _answering(status, body, contentType: contentType));
  return thrown!;
}

/// Regression tests for the login failure message.
///
/// A rejected login used to become `Exception('Credenciales inválidas')` no
/// matter what the backend said, so a mistyped company id -- which the backend
/// distinguishes with a 404 and a sentence naming the id as the problem -- was
/// reported to the user as a wrong password. They then debugged the one half
/// that was right. The fix is for the client to repeat the backend's `detail`
/// and to fall back to the old message whenever that `detail` is unusable.
///
/// The fallbacks are the bulk of the tests on purpose: they are what keep the
/// change from trading a misleading message for a worse one. A body the client
/// cannot parse must not reach the user as a `FormatException`, and a `detail`
/// that is not a human sentence must not either.
void main() {
  group('a non-200 login surfaces the backend detail', () {
    test('404 for an unknown company id is reported verbatim', () async {
      final thrown = await _loginAgainst(
          404, json.encode(<String, Object?>{'detail': _unknownCompanyDetail}));

      expect(thrown, isA<Exception>());
      expect(_shownToUser(thrown), _unknownCompanyDetail,
          reason: 'the user must read the sentence the backend wrote, not a '
              'guess about which half of the login was wrong');
    });

    test('401 is reported verbatim', () async {
      // Deliberately NOT the real 401 detail: the backend sends
      // "Credenciales inválidas" for a wrong password, which is the same string
      // the client used to hardcode, so a test using it would pass against the
      // bug and prove nothing. Any other sentence keeps the test honest about
      // what it is checking -- the detail is surfaced whatever the status.
      const detail = 'La contraseña no coincide';
      final thrown = await _loginAgainst(
          401, json.encode(<String, Object?>{'detail': detail}));

      expect(thrown, isA<Exception>());
      expect(_shownToUser(thrown), detail);
    });

    test('a 400 is reported verbatim too -- the detail is what decides, '
        'not the status code', () async {
      const detail = 'Se requiere tenant_id (client_id)';
      final thrown = await _loginAgainst(
          400, json.encode(<String, Object?>{'detail': detail}));

      expect(_shownToUser(thrown), detail,
          reason: 'hardcoding on status code would reintroduce the same class '
              'of bug one status code over');
    });

    test('the detail keeps its accents', () async {
      // `http` decodes an `application/json` body as utf8, so this passes
      // because of how the response is read, not by accident. A client that
      // decoded as latin1 would show "est? registrado" -- a fix that made the
      // message correct but unreadable.
      final thrown = await _loginAgainst(
          404, json.encode(<String, Object?>{'detail': _unknownCompanyDetail}));

      expect(_shownToUser(thrown), contains('está'));
      expect(_shownToUser(thrown), contains('Verificá'));
    });
  });

  group('an unusable body falls back to the generic message', () {
    test('a non-JSON body does not surface a parse error', () async {
      final thrown = await _loginAgainst(502, '<html>Bad Gateway</html>',
          contentType: 'text/html');

      expect(thrown, isNot(isA<FormatException>()),
          reason: 'the user is told about the login, not about our parser');
      expect(_shownToUser(thrown), _genericLoginMessage);
    });

    test('an empty body does not surface a parse error', () async {
      final thrown = await _loginAgainst(500, '');

      expect(thrown, isNot(isA<FormatException>()));
      expect(_shownToUser(thrown), _genericLoginMessage);
    });

    test('a JSON body that is not a map falls back', () async {
      for (final body in <String>['[]', '"nope"', '42', 'null']) {
        final thrown = await _loginAgainst(400, body);
        expect(_shownToUser(thrown), _genericLoginMessage,
            reason: 'a top-level $body is not a detail');
      }
    });

    test('a map with no detail key falls back', () async {
      final thrown = await _loginAgainst(
          400, json.encode(<String, Object?>{'message': 'algo falló'}));

      expect(_shownToUser(thrown), _genericLoginMessage);
    });

    test('a non-string detail falls back -- this is the real 422 payload',
        () async {
      // Not hypothetical: `POST /auth/login` with a missing form field answers
      // 422 with `detail` as a LIST of objects. Stringifying it would put
      // framework internals in front of the user.
      final thrown = await _loginAgainst(422, json.encode(<String, Object?>{
        'detail': <Object?>[
          <String, Object?>{
            'type': 'missing',
            'loc': <Object?>['body', 'password'],
            'msg': 'Field required',
            'input': null,
          },
        ],
      }));

      expect(_shownToUser(thrown), _genericLoginMessage,
          reason: 'a list of validation objects is not something to show a user');
    });

    test('a detail that is only whitespace falls back', () async {
      final thrown =
          await _loginAgainst(400, json.encode(<String, Object?>{'detail': '   '}));

      expect(_shownToUser(thrown), _genericLoginMessage,
          reason: 'whitespace is technically a string and says nothing');
    });
  });

  group('the user-visible outcome, through AuthProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tenant_id': 'empresa-inexistente',
      });
    });

    test('auth.error is the backend sentence, not "Credenciales inválidas"',
        () async {
      final api = ApiService(baseUrl: _baseUrl);
      final auth = AuthProvider(api: api);

      await http.runWithClient(() async {
        await auth.init();
        expect(await auth.login('operario', 'secreto'), isFalse);
      }, () => _answering(404,
              json.encode(<String, Object?>{'detail': _unknownCompanyDetail})));

      expect(auth.error, _unknownCompanyDetail,
          reason: 'this string is painted on the login screen');
      expect(auth.error, isNot(contains('Exception')),
          reason: 'AuthProvider strips one "Exception: " prefix; a message '
              'that carried its own would be left with a stub');
    });

  });
}
