import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';

/// Regression tests for the family page localization bug: the English map
/// used to carry Tagalog values for the group labels ("Mga Anak", "Mga
/// Apo", …), so toggling to English left those strings untranslated.
void main() {
  Future<void> pumpFamilyPage(
    WidgetTester tester,
    LanguageProvider lang,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: lang,
        child: const MaterialApp(home: FamilyPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('family page re-renders fully when switched to English', (
    tester,
  ) async {
    final lang = LanguageProvider();
    await pumpFamilyPage(tester, lang);

    // Tagalog defaults (provider starts in Tagalog).
    expect(find.text('Mga Anak'), findsOneWidget);
    expect(find.text('Mga Kapatid'), findsOneWidget);
    expect(find.text('3 anak'), findsOneWidget);

    // Toggle to English — every family string must translate immediately.
    lang.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Siblings'), findsOneWidget);
    // Filter chip + section header both read 'Grandchildren'. The section
    // header sits below the fold, so search cached off-screen widgets too.
    expect(find.text('Grandchildren', skipOffstage: false), findsNWidgets(2));
    expect(find.text('3 children'), findsOneWidget);
    expect(find.text('8 members', skipOffstage: false), findsOneWidget);

    // No Tagalog leftovers may remain anywhere in the tree.
    expect(find.text('Mga Anak'), findsNothing);
    expect(find.text('Mga Kapatid'), findsNothing);
    expect(find.text('Mga Apo'), findsNothing);
  });

  testWidgets('family page translates to Bicol group labels', (tester) async {
    final lang = LanguageProvider();
    await pumpFamilyPage(tester, lang);

    lang.setLanguage(AppLanguage.bicol);
    await tester.pumpAndSettle();

    expect(find.text('Mga Aki'), findsOneWidget);
    expect(find.text('Mga Magturugang'), findsOneWidget);
    expect(find.text('Mga Anak'), findsNothing);
  });
}
