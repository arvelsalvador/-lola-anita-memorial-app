import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';

/// Geometry regression tests for the family page descent lines: the
/// org-chart branch connector (_TreeBranchPainter) must clear the section
/// header text vertically and its drops must land on the card centers;
/// the Mga Apo grid draws straight per-column lines (_SpineLines) instead
/// of a bus — through its header and card→card down each branch column —
/// and those must clear its header too.
///
/// Everything is asserted at scroll 0: the list builds all sections there
/// (cacheExtent 2000), while scrolling to the bottom disposes the sections
/// above the viewport, which would hide them from the finders.
void main() {
  Finder connectorFinder() => find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_TreeBranchConnector',
  );

  Finder spineFinder() =>
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SpineLines');

  double topOf(RenderBox box) => box.localToGlobal(Offset.zero).dy;

  double bottomOf(RenderBox box) =>
      box.localToGlobal(Offset.zero).dy + box.size.height;

  /// Boxes of [finder] sorted top→bottom.
  List<RenderBox> boxesOf(Finder finder) =>
      finder
          .evaluate()
          .map((e) => e.renderObject! as RenderBox)
          .toList()
        ..sort((a, b) => topOf(a).compareTo(topOf(b)));

  /// First connector box whose top edge sits at or below [minTop].
  RenderBox? connectorBelow(double minTop) {
    for (final b in boxesOf(connectorFinder())) {
      if (topOf(b) >= minTop) return b;
    }
    return null;
  }

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

    // The section's own connector — the first one at or below the header.
    // The lookup is anchored to the header rather than a blind `.first`
    // so it stays correct no matter how the groups are ordered.
    final connector = connectorBelow(bottomOf(titleBox) - 1);
    expect(connector, isNotNull, reason: 'no connector below "Mga Anak"');

    // Bus sits 10px below the connector box's top edge.
    final busY = topOf(connector!) + 10;
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

  testWidgets('apo straight lines clear the "Mga Apo" header text', (
    tester,
  ) async {
    await pumpFamilyPage(tester);

    // Bring the grandchildren section into the build range with a small
    // scroll — scrolling to the very bottom would dispose the sections
    // above it. 'Mga Apo' also appears on a filter chip — anchor on the
    // section header's unique count text instead.
    await tester.scrollUntilVisible(
      find.text('8 miyembro'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final countFinder = find.text('8 miyembro');
    expect(countFinder, findsOneWidget);
    final headerBottom = bottomOf(
      tester.renderObject<RenderBox>(countFinder),
    );

    // Straight per-column lines below the header (the descent onto the
    // first card row) — and no bus connector anymore.
    final spines = boxesOf(
      spineFinder(),
    ).where((b) => topOf(b) >= headerBottom).toList();
    expect(
      spines,
      isNotEmpty,
      reason: 'no straight descent lines below the "Mga Apo" header',
    );
    expect(
      topOf(spines.first),
      greaterThanOrEqualTo(headerBottom),
      reason: 'apo descent lines overlap the section header text',
    );
    expect(
      connectorBelow(headerBottom),
      isNull,
      reason: 'the "Mga Apo" grid must not render a bus connector',
    );
  });

  testWidgets(
    'every section has descent lines below its header '
    '(branch connector, or straight spines for Mga Apo)',
    (tester) async {
      await pumpFamilyPage(tester);

      // Jump to a fixed mid-scroll offset: far enough that the apo
      // section is built, close enough that the Kapatid and Anak sections
      // above it are still alive (scrolling to the bottom disposes them).
      final position = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      ).position;
      position.jumpTo(300);
      await tester.pumpAndSettle();

      // Mga Anak and Mga Kapatid render the org-chart branch connector;
      // Mga Apo draws straight per-column lines instead. Any new group
      // added later flows through FamilyGroupSection and inherits the
      // connector automatically, so the connector count must stay in
      // lockstep with the non-apo card-row sections.
      expect(
        boxesOf(connectorFinder()).length,
        2,
        reason:
            'Mga Anak and Mga Kapatid must each render exactly one branch '
            'connector',
      );

      // 'Mga Apo' also appears on a filter chip — anchor on the unique
      // count text for that section's header.
      final sections = <String, Finder>{
        'Mga Anak': find.text('Mga Anak'),
        'Mga Kapatid': find.text('Mga Kapatid'),
        'Mga Apo': find.text('8 miyembro'),
      };

      sections.forEach((label, headerFinder) {
        expect(
          headerFinder,
          findsOneWidget,
          reason: '"$label" header not found or not unique',
        );
        final headerBottom = bottomOf(
          tester.renderObject<RenderBox>(headerFinder),
        );

        final below = [
          ...boxesOf(connectorFinder()),
          ...boxesOf(spineFinder()),
        ].where((b) => topOf(b) >= headerBottom - 6).toList();
        expect(
          below,
          isNotEmpty,
          reason: 'no descent lines below the "$label" header',
        );

        expect(
          topOf(below.first),
          greaterThanOrEqualTo(headerBottom - 6),
          reason: '"$label" descent lines do not clear its header text',
        );
      });
    },
  );
}
