import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agua/features/help/screens/help_screen.dart';
import 'package:agua/main.dart' as app;

/// Boot smoke test: the real entry point must render a screen without throwing.
///
/// It goes through `app.main()` rather than `pumpWidget(const AguaApp())`
/// because `AguaApp` now reads `AuthProvider` from the widget tree, and
/// `pumpWidget` builds it without the provider installed.
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await app.main();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Instructivo renders without a provider', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Instructivo'), findsWidgets);
  });
}
