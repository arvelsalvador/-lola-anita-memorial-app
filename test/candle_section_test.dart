import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/tribute_widgets.dart';

/// Regression test for the CandleSection crash: when Firebase is not
/// configured (as in widget tests / the current app), the section used to
/// throw a TypeError from a bad stream cast and break the Tribute tab.
void main() {
  testWidgets('CandleSection builds without throwing when Firebase is absent',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        // Force English so the expected strings below are deterministic.
        create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: CandleSection())),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Light a candle'), findsNWidgets(2)); // label + button
    expect(find.textContaining('124'), findsOneWidget);
  });

  testWidgets('Lighting a candle increments locally without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        // Force English so the expected strings below are deterministic.
        create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: CandleSection())),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Light a candle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('125'), findsOneWidget);
  });
}
