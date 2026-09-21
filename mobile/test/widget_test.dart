import 'package:flutter_test/flutter_test.dart';

import 'package:agua/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AguaApp());
    await tester.pumpAndSettle();
  });
}
