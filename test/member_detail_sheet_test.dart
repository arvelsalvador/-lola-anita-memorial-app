import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';

/// Tests for the shared member-detail bottom sheet: every relative card
/// (Mga Anak, Mga Kapatid, Mga Apo) opens the same popup fed with that
/// person's data, and the sheet dismisses via X button or barrier tap.
void main() {
  Future<void> pumpFamilyPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: LanguageProvider(),
        child: const MaterialApp(home: FamilyPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollToSiblings(WidgetTester tester) async {
    // Bring the Mga Kapatid section on-screen.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an anak card opens the detail sheet with full info', (
    tester,
  ) async {
    await pumpFamilyPage(tester);

    // Card text only before the tap.
    expect(find.text('Gernan Lumbao'), findsOneWidget);

    await tester.tap(find.text('Gernan Lumbao'));
    await tester.pumpAndSettle();

    // Sheet shows the name (card + sheet = 2 instances), relation, bio,
    // about-title, and close button.
    expect(find.text('Gernan Lumbao'), findsNWidgets(2));
    expect(find.text('Anak na lalaki'), findsWidgets);
    expect(find.text('TUNGKOL SA KANYA'), findsOneWidget);
    expect(
      find.textContaining('Ang kanilang panganay na anak na lalaki'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('sheet closes via the X button', (tester) async {
    await pumpFamilyPage(tester);

    await tester.tap(find.text('Gernan Lumbao'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Back to just the card instance.
    expect(find.text('Gernan Lumbao'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('sheet closes when tapping outside (barrier)', (tester) async {
    await pumpFamilyPage(tester);
    await scrollToSiblings(tester);

    await tester.tap(find.text('Sonia Daiz'));
    await tester.pumpAndSettle();
    expect(find.text('Sonia Daiz'), findsNWidgets(2));

    // Top-left corner is barrier area — the sheet hugs the bottom.
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(find.text('Sonia Daiz'), findsOneWidget);
  });

  testWidgets('kapatid sheet content scrolls without crashing', (tester) async {
    await pumpFamilyPage(tester);
    await scrollToSiblings(tester);

    await tester.tap(find.text('Obit Daiz'));
    await tester.pumpAndSettle();

    final aboutFinder = find.text('TUNGKOL SA KANYA');
    expect(aboutFinder, findsOneWidget);

    // Drag the sheet's scrollable content up and back down.
    await tester.drag(aboutFinder, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.drag(aboutFinder, const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(find.text('Obit Daiz'), findsNWidgets(2));
  });

  testWidgets('tapping an apo card opens the sheet with age info', (
    tester,
  ) async {
    await pumpFamilyPage(tester);

    // Bring the grandchildren pager on-screen.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    // Apo cards render first names only.
    await tester.tap(find.text('Alyanna'));
    await tester.pumpAndSettle();

    // The sheet carries the full name; the card behind shows the short one.
    expect(find.text('Alyanna Daiz'), findsOneWidget);
    expect(find.text('Apo'), findsWidgets);
    expect(find.text('6 taong gulang'), findsWidgets);
    // No bio/photos for grandchildren — no About section in this sheet.
    expect(find.text('TUNGKOL SA KANYA'), findsNothing);
  });
}
