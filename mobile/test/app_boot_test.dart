import 'package:agua/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> storedSession() => <String, Object>{
      'tenant_id': 'demo',
      'access_token': 'header.payload.signature',
      'refresh_token': 'refresh-token',
      'user_json': '{"id":"1","tenant_id":"demo","username":"operario",'
          '"email":"op@demo.com","rol":"OPERARIO","activo":true,'
          '"created_at":"2026-01-01T00:00:00"}',
    };

void main() {
  testWidgets('boots to the login screen when there is no stored session',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Nueva Muestra'), findsNothing);
  });

  testWidgets('restores a stored session and boots straight to home',
      (tester) async {
    SharedPreferences.setMockInitialValues(storedSession());

    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Home is reachable without touching the login form: this is the
    // regression test for the `initialRoute` race.
    expect(find.text('Nueva Muestra'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);
  });

  testWidgets('falls back to login when the stored session is unusable',
      (tester) async {
    // Corrupt JSON: restore must degrade, never hang on a splash.
    SharedPreferences.setMockInitialValues(<String, Object>{
      ...storedSession(),
      'user_json': '{not json',
    });

    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });
}
