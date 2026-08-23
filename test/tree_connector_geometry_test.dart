import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';

/// Geometry regression tests for the org-chart branch connector
/// (_TreeBranchPainter): the horizontal bus must clear the section header
/// text vertically, and every drop must land on its card's center.
void main() {
  Finder connectorFinder() => find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_TreeBranchConnector',
  );

  double topOf(RenderBox box) => box.localToGlobal(Offset.zero).dy;

  double bottomOf(RenderBox box) =>
      box.localToGlobal(Offset.zero).dy + box.size.height;

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

  testWidgets('bus line clears the "Mga Anak" header text', (tester) async {
    await pumpFamilyPage(tester);

    final titleBox = tester.renderObject<RenderBox>(find.text('Mga Anak'));
    final countBox = tester.renderObject<RenderBox>(find.text('3 anak'));
    final connector = tester.renderObject<RenderBox>(connectorFinder().first);

    // Bus sits 10px below the connector box's top edge.
    final busY = topOf(connector) + 10;
    final titleBottom = bottomOf(titleBox);
    final countBottom = bottomOf(countBox);

    // ignore: avoid_print
    print(
      'geometry: titleBottom=$titleBottom countBottom=$countBottom '
      'connectorTop=${topOf(connector)} busY=$busY',
    );

    expect(
      busY,
      greaterThanOrEqualTo(titleBottom + 4),
      reason: 'bus line overlaps the section title text',
    );
    expect(
      busY,
      greaterThanOrEqualTo(countBottom + 4),
      reason: 'bus line overlaps the section count text',
    );
  });

  testWidgets('drops land on the horizontal center of their cards', (
    tester,
  ) async {
    await pumpFamilyPage(tester);

    final connector = tester.renderObject<RenderBox>(connectorFinder().first);
    final connectorWidth = connector.size.width;

    // First-row card centers under equal-width Expanded cells.
    final expectedCenters = [
      for (var i = 0; i < 3; i++) (i + 0.5) * connectorWidth / 3,
    ];

    final cards = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_MemberThumbnailCard',
    );
    expect(cards.evaluate().length, greaterThanOrEqualTo(3));

    for (var i = 0; i < 3; i++) {
      final cardBox = tester.renderObject<RenderBox>(cards.at(i));
      final cardCenterDx =
          cardBox.localToGlobal(Offset(cardBox.size.width / 2, 0)).dx -
          connector.localToGlobal(Offset.zero).dx;
      expect(
        cardCenterDx,
        closeTo(expectedCenters[i], 1.0),
        reason: 'drop $i does not align with card $i center',
      );
    }
  });

  testWidgets('apo pager bus clears the "Mga Apo" header text', (tester) async {
    await pumpFamilyPage(tester);

    // Bring the grandchildren section on-screen.
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    final titleFinder = find.text('Mga Apo');
    expect(titleFinder, findsOneWidget);
    final titleBox = tester.renderObject<RenderBox>(titleFinder);
    final connector = tester.renderObject<RenderBox>(connectorFinder().last);

    final busY = topOf(connector) + 10;
    expect(
      busY,
      greaterThanOrEqualTo(bottomOf(titleBox) + 4),
      reason: 'apo pager bus line overlaps the section title text',
    );
  });

  testWidgets(
    'every section with member cards has exactly one branch connector '
    'below its header (guards future sections too)',
    (tester) async {
      await pumpFamilyPage(tester);

      // Bring all sections' widgets into the built/cached range.
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();

      List<RenderBox> connectorBoxes() =>
          connectorFinder()
              .evaluate()
              .map((e) => e.renderObject! as RenderBox)
              .toList()
            ..sort((a, b) => topOf(a).compareTo(topOf(b)));

      // Sections are rendered from FamilyController.data.groups; today those
      // are Mga Anak, Mga Kapatid, and Mga Apo. Any group added later flows
      // through the same FamilyGroupSection paths, so this count must stay
      // in lockstep with the data — one connector per card-row section
      // (the apo pager materializes exactly one page at rest).
      final sectionLabels = ['Mga Anak', 'Mga Kapatid', 'Mga Apo'];
      expect(
        connectorBoxes().length,
        sectionLabels.length,
        reason:
            'section/connector count mismatch — a card-row section is '
            'missing its branch connector',
      );

      for (final label in sectionLabels) {
        final headerFinder = find.text(label);
        expect(
          headerFinder,
          findsOneWidget,
          reason: '"$label" header not found or not unique',
        );
        final headerBottom = bottomOf(
          tester.renderObject<RenderBox>(headerFinder),
        );

        final below = connectorBoxes()
            .where((b) => topOf(b) >= headerBottom)
            .toList();
        expect(
          below,
          isNotEmpty,
          reason: 'no branch connector below the "$label" header',
        );

        final busY = topOf(below.first) + 10;
        expect(
          busY,
          greaterThanOrEqualTo(headerBottom + 4),
          reason: '"$label" bus line does not clear its header text',
        );
      }
    },
  );
}
