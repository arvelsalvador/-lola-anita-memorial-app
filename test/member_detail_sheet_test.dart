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

  /// Brings a member card on-screen before tapping it. The siblings group
  /// comes first and children second, so most cards start below the fold —
  /// tapping an off-screen card silently misses and the sheet never opens.
  Future<void> scrollToMember(WidgetTester tester, String name) async {
    await tester.scrollUntilVisible(
      find.text(name),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an anak card opens the detail sheet with full info', (
    tester,
  ) async {
    await pumpFamilyPage(tester);

    // Card text only before the tap.
    expect(find.text('Gernan Lumbao'), findsOneWidget);

    // The anak section starts below the fold (siblings come first now);
    // bring the card on-screen or the tap lands outside the viewport.
    await scrollToMember(tester, 'Gernan Lumbao');
    await tester.tap(find.text('Gernan Lumbao'));
    await tester.pumpAndSettle();

    // Sheet shows the name (card + sheet = 2 instances), relation, full
    // story, identity section, and close button.
    expect(find.text('Gernan Lumbao'), findsNWidgets(2));
    expect(find.text('Anak na lalaki'), findsWidgets);
    expect(find.text('BUONG KUWENTO'), findsOneWidget);
    expect(find.text('PAGKAKAKILANLAN'), findsOneWidget);
    expect(find.text('PAMILYA'), findsOneWidget);
    // Identity section always carries a Role row.
    expect(find.text('Role'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('sheet closes via the X button', (tester) async {
    await pumpFamilyPage(tester);

    await scrollToMember(tester, 'Gernan Lumbao');
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
    await scrollToMember(tester, 'Sonia Daiz');

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
    await scrollToMember(tester, 'Roberto Daiz');

    await tester.tap(find.text('Roberto Daiz'));
    await tester.pumpAndSettle();

    final storyFinder = find.text('BUONG KUWENTO');
    expect(storyFinder, findsOneWidget);

    // Drag the sheet's scrollable content up and back down.
    await tester.drag(storyFinder, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.drag(storyFinder, const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(find.text('Roberto Daiz'), findsNWidgets(2));
  });

  testWidgets('tapping an apo card opens the member sheet', (tester) async {
    await pumpFamilyPage(tester);

    // Bring the grandchildren section on-screen (it is the last section).
    await tester.scrollUntilVisible(
      find.text('Hanna Lumbao'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hanna Lumbao'));
    await tester.pumpAndSettle();

    // Sheet shows the same name (card + sheet = 2 instances) plus the
    // "Apo" relation. Grandchildren carry a short bio, which the sheet
    // renders under the Full Story section.
    expect(find.text('Hanna Lumbao'), findsNWidgets(2));
    expect(find.text('Apo'), findsWidgets);
    expect(find.text('BUONG KUWENTO'), findsOneWidget);
  });
}
