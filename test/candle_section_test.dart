import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/widgets/candle_section.dart';

/// Regression test for the CandleSection crash: when Firebase is not
/// configured (as in widget tests / the current app), the section used to
/// throw a TypeError from a bad stream cast and break the candle tab.
void main() {
  Widget wrap(Widget child) => ChangeNotifierProvider(
    // Force English so the expected strings below are deterministic.
    create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CandleSection(tributeController: TributeController()),
        ),
      ),
    ),
  );

  Future<void> pumpWrapped(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const SizedBox()));
  }

  testWidgets('CandleSection builds without throwing when Firebase is absent', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    expect(tester.takeException(), isNull);
    // Title + the single full-width light button. The video asset can't
    // initialize in widget tests, so the fallback medallion shows.
    expect(find.text('Light a candle'), findsNWidgets(2));
    expect(find.text('124 candles lit'), findsOneWidget);
  });

  testWidgets('Lighting a candle increments locally without throwing', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    // The overlaid button on the video circle lights the candle (and
    // would play the one-shot video on a real device).
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Light a candle').first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('125 candles lit'), findsOneWidget);
    // The lit title is a thank-you with a condolences subtitle.
    expect(find.text('Thank You Very Much'), findsOneWidget);
    expect(
      find.text(
        'To everyone sharing their condolences and love for Nanay Nita.',
      ),
      findsOneWidget,
    );

    // The words-for-Nanay bar sits behind the Condolences button even
    // when lit — tap it to reveal the box (no popup) with send
    // disabled on an empty draft.
    expect(
      find.text('Write your message for Nanay…'),
      findsNothing,
    );
    await tester.tap(find.text('Condolences'));
    await tester.pump();
    expect(
      find.text('Write your message for Nanay…'),
      findsOneWidget,
    );
    final sendButton = find.widgetWithText(ElevatedButton, 'Send');
    expect(sendButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Thank you, Nanay');
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(sendButton).onPressed,
      isNotNull,
    );
    await tester.tap(sendButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Offline backend: no throw, message still gets its thanks.
    expect(tester.takeException(), isNull);
    expect(
      find.text('Your message has reached Nanay 🕊️'),
      findsOneWidget,
    );
  });

  testWidgets('Condolences button reveals message box and footer', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    // Default: box and closing quote hidden behind the button.
    expect(find.text('Write your message for Nanay…'), findsNothing);
    expect(find.text('With every flame, a memory.'), findsNothing);
    expect(find.text('Condolences'), findsOneWidget);
    // Keepsake divider above still renders.
    expect(find.text('Her memory keeps glowing on'), findsOneWidget);

    await tester.tap(find.text('Condolences'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Write your message for Nanay…'), findsOneWidget);
    expect(find.text('With every flame, a memory.'), findsOneWidget);
    // Still unlit — the button did not light the candle.
    expect(find.text('124 candles lit'), findsOneWidget);
  });
}
