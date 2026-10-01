import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/views/condolences/candle_section.dart';

/// CandleSection is now message-first: splash owns the visitor name,
/// Pakikiramay only asks "Mensahe para kay Nanay" before lighting and
/// shows thanks-only after lighting (no second message box).
void main() {
  setUpAll(() {
    // VisibilityDetector defers its callbacks on a periodic timer, which
    // otherwise stays pending at teardown and fails the test with
    // "A Timer is still pending even after the widget tree was disposed."
    // (See the package README's "Widget tests" section.)
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  test('validateCandleName still accepts real names (splash gate use)', () {
    expect(validateCandleName(''), 'candle_name_required');
    expect(validateCandleName('   '), 'candle_name_required');
    expect(validateCandleName('Marc'), isNull);
    expect(validateCandleName('Princess'), isNull);
    expect(validateCandleName('Maria Clara'), isNull);
    expect(validateCandleName('Anne-Marie'), isNull);
    expect(validateCandleName("D'Angelo"), isNull);
    expect(validateCandleName('Sy'), isNull);
    expect(validateCandleName('Rose-ann'), isNull);
    expect(validateCandleName('lyca13'), 'candle_name_invalid');
    expect(validateCandleName('Marc123'), 'candle_name_invalid');
    expect(validateCandleName('!!!'), 'candle_name_invalid');
    expect(validateCandleName('A'), 'candle_name_invalid');
    expect(validateCandleName('wxxz'), 'candle_name_invalid');
  });

  test('validateCandleName blocks keyboard-mash gibberish', () {
    expect(validateCandleName('awdasdawsdawawd'), 'candle_name_invalid');
    expect(validateCandleName('asdfghjkl'), 'candle_name_invalid');
    expect(validateCandleName('qqqqqq'), 'candle_name_invalid');
    expect(validateCandleName('bcdfgh'), 'candle_name_invalid');
    expect(validateCandleName('Ab Ab Ab'), 'candle_name_invalid');
  });

  Widget wrap(Widget child) => ChangeNotifierProvider(
    // Force English so the expected strings below are deterministic.
    create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CandleSection(condolencesController: CondolencesController()),
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

  Finder lightButton() =>
      find.widgetWithText(ElevatedButton, 'Light a candle');

  testWidgets('CandleSection asks message first, no name field', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    expect(tester.takeException(), isNull);
    // Title + the single full-width light button. The video asset can't
    // initialize in widget tests, so the fallback medallion shows.
    expect(find.text('Light a candle'), findsNWidgets(2));
    expect(find.text('124 candles lit'), findsOneWidget);
    // Message field is shown before lighting; no name field, no Send.
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('What would you like to say to Nanay?'),
      findsOneWidget,
    );
    expect(find.text('Write your message for Nanay…'), findsOneWidget);
    expect(find.text('Your name…'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Send'), findsNothing);
    expect(find.text('With every flame, a memory.'), findsNothing);
    // Mandatory message: empty means the light button is disabled with
    // the "write your message first" prompt visible under the button.
    expect(tester.widget<ElevatedButton>(lightButton()).onPressed, isNull);
    expect(
      find.text('Please write your message for Nanay to light a candle.'),
      findsOneWidget,
    );
  });

  testWidgets('Empty message blocks lighting, typing enables it', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    // Whitespace-only still counts as empty.
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(lightButton()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Thank you, Nanay');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(lightButton()).onPressed, isNotNull);
    // Valid message hides the required prompt.
    expect(
      find.text('Please write your message for Nanay to light a candle.'),
      findsNothing,
    );
  });

  testWidgets('Lighting shows thanks-only, no second message box', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    await tester.enterText(find.byType(TextField), 'Thank you, Nanay');
    await tester.pump();

    // The overlaid button on the video circle lights the candle (and
    // would play the one-shot video on a real device).
    await tester.tap(lightButton().first);
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

    // Thanks-only: message field and Send are gone after lighting, and
    // the removed slogan/attribution lines never reappear.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Write your message for Nanay…'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Send'), findsNothing);
    expect(find.text('With every flame, a memory.'), findsNothing);
  });

  testWidgets('Offline after lighting shows go-online note, no names', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    await tester.enterText(find.byType(TextField), 'Thank you, Nanay');
    await tester.pump();
    await tester.tap(lightButton().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    // Supabase is uninitialized in tests = offline: list hides,
    // go-online note + retry show, message text never leaks into list.
    expect(find.text('Who remembers Nanay'), findsOneWidget);
    expect(
      find.text('Go online to see who remembers Nanay.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Thank you, Nanay'), findsNothing);
  });

  testWidgets('Message box appears only before lighting', (
    WidgetTester tester,
  ) async {
    await pumpWrapped(tester);

    // Default: message field visible, removed slogan line absent.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Write your message for Nanay…'), findsOneWidget);
    expect(find.text('With every flame, a memory.'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Marc');
    await tester.pump();
    await tester.tap(lightButton().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('With every flame, a memory.'), findsNothing);
    expect(find.text('125 candles lit'), findsOneWidget);
    expect(find.text('Thank You Very Much'), findsOneWidget);
  });
}
