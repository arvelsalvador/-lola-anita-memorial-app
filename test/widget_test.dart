import 'package:flutter_test/flutter_test.dart';

import 'package:nita/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LolaApp());
    expect(find.byType(LolaApp), findsOneWidget);
  });
}
