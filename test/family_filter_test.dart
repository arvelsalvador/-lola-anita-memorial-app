import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family/family_page.dart';

// The "Lahat / Direktang pamilya / Mga Apo" filter chips were removed from
// the Family page — this file now guards that they stay gone while the
// rest of the page (header, search, sections) keeps rendering.
void main() {
  Future<void> pumpFamilyPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(home: FamilyPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('family page renders without filter chips', (tester) async {
    await pumpFamilyPage(tester);

    // Header + search still render.
    expect(find.text('Pamilyang Lumbao'), findsOneWidget);
    expect(find.text('Maghanap ng kapamilya'), findsOneWidget);

    // No filter chip row anywhere.
    expect(find.byKey(const Key('family_filter_chips')), findsNothing);

    // The page scrolls to its sections without throwing.
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('Mga Apo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
