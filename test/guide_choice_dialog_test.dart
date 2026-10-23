import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/guide/guide_choice_dialog.dart';

/// The guide-choice popup puts its close button in a floating overlay at the
/// card's top-right corner. These tests lock in the gutter that keeps it from
/// landing on the title copy (long Tagalog/Bicol titles used to run right
/// underneath the X on narrow phones).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget harness(LanguageProvider lang) => ChangeNotifierProvider.value(
    value: lang,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showGuideChoiceDialog(context),
              child: const Text('open guide choice'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> openDialog(WidgetTester tester, LanguageProvider lang) async {
    await tester.pumpWidget(harness(lang));
    await tester.tap(find.text('open guide choice'));
    await tester.pumpAndSettle();
  }

  for (final (language, title) in [
    (AppLanguage.tagalog, 'Gusto mo bang samahan kita?'),
    (AppLanguage.english, 'Would you like me to guide you?'),
    (AppLanguage.bicol, 'Gusto mo daw na ibahan taka?'),
  ]) {
    testWidgets('${language.name} title clears the close button on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await openDialog(tester, LanguageProvider()..setLanguage(language));

      final titleRect = tester.getRect(find.text(title));
      final closeRect = tester.getRect(find.byIcon(Icons.close_rounded));

      // The two do share vertical space — that is exactly why the title needs
      // a right gutter — but they must never overlap horizontally.
      expect(titleRect.top, lessThan(closeRect.bottom));
      expect(closeRect.top, lessThan(titleRect.bottom));
      expect(
        closeRect.left,
        greaterThanOrEqualTo(titleRect.right),
        reason: 'the X must sit clear of "$title"',
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the card fits and the X closes the dialog', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openDialog(tester, LanguageProvider());

    expect(find.text('Gusto mo bang samahan kita?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Gusto mo bang samahan kita?'), findsNothing);
    expect(find.text('open guide choice'), findsOneWidget);
  });
}
