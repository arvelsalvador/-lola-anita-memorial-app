import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/controllers/family_controller.dart';

/// Regression tests for the Mga Apo grid layout: grandchildren must be
/// stacked into vertical columns by their parent branch (one column per
/// parent's children — Hanna Lumbao & Audrey Lumbao under Gernan, Rodel Lumbao Jr. & Rose-ann Lumbao
/// under Rodel Sr., Arvel Salvador/Aivan Salvador/Honey Salvador/Daniel Salvador under Lorie) instead of arbitrary
/// fixed-size chunks that split a family branch across rows.
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

  /// Overlay-center of the card showing `name` (if it's mounted).
  Offset? centerOf(WidgetTester tester, String name) {
    final finder = find.text(name);
    if (finder.evaluate().isEmpty) return null;
    return tester.getCenter(finder);
  }

  /// Top edge of the card text showing `name` (if it's mounted).
  double? topOf(WidgetTester tester, String name) {
    final finder = find.text(name);
    if (finder.evaluate().isEmpty) return null;
    return tester.getTopLeft(finder).dy;
  }

  testWidgets('Mga Apo stacks each parent branch in its own column '
      '(2 / 2 / 4)', (tester) async {
    await pumpFamilyPage(tester);

    // Scroll the grandchildren section into view (it is the last section).
    await tester.scrollUntilVisible(
      find.text('8 miyembro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Apo cards show the full name.
    final hanna = centerOf(tester, 'Hanna Lumbao');
    final audrey = centerOf(tester, 'Audrey Lumbao');
    final jongjong = centerOf(tester, 'Rodel Lumbao Jr.');
    final roseann = centerOf(tester, 'Rose-ann Lumbao');
    final arvel = centerOf(tester, 'Arvel Salvador');
    final aivan = centerOf(tester, 'Aivan Salvador');
    final honey = centerOf(tester, 'Honey Salvador');
    final daniel = centerOf(tester, 'Daniel Salvador');

    expect(hanna, isNotNull);
    expect(audrey, isNotNull);
    expect(jongjong, isNotNull);
    expect(roseann, isNotNull);
    expect(arvel, isNotNull);
    expect(aivan, isNotNull);
    expect(honey, isNotNull);
    expect(daniel, isNotNull);

    // Same parent → same column (same center x): Gernan's kids, Rodel Sr.'s
    // kids, Lorie's kids.
    expect(
      hanna!.dx,
      closeTo(audrey!.dx, 1.0),
      reason: 'Hanna Lumbao & Audrey Lumbao must share a column',
    );
    expect(
      jongjong!.dx,
      closeTo(roseann!.dx, 1.0),
      reason: 'Rodel Lumbao Jr. & Rose-ann Lumbao must share a column',
    );

    // Lorie's four kids share one column.
    expect(arvel!.dx, closeTo(aivan!.dx, 1.0), reason: 'Arvel Salvador & Aivan Salvador share a column');
    expect(
      honey!.dx,
      closeTo(daniel!.dx, 1.0),
      reason: 'Honey Salvador & Daniel Salvador share a column',
    );
    expect(
      arvel.dx,
      closeTo(honey.dx, 1.0),
      reason: "Lorie's four kids must share one column",
    );

    // The first card of every branch column opens on a shared first row.
    // Compared at the name text's top edge: all portraits share one fixed
    // size, so the tops align exactly even when a longer name (e.g.
    // "Hanna Lumbao") wraps and shifts the text's center down a line.
    expect(
      topOf(tester, 'Hanna Lumbao'),
      closeTo(topOf(tester, 'Rodel Lumbao Jr.')!, 1.0),
      reason: 'branch columns must open on a shared first row',
    );
    expect(
      topOf(tester, 'Hanna Lumbao'),
      closeTo(topOf(tester, 'Arvel Salvador')!, 1.0),
      reason: 'branch columns must open on a shared first row',
    );

    // Within a column the cards stack top→bottom.
    expect(
      audrey.dy,
      greaterThan(hanna.dy),
      reason: 'Audrey Lumbao stacks below Hanna Lumbao',
    );
    expect(
      roseann.dy,
      greaterThan(jongjong.dy),
      reason: 'Rose-ann Lumbao stacks below Rodel Lumbao Jr.',
    );
    expect(aivan.dy, greaterThan(arvel.dy), reason: 'Aivan Salvador stacks below Arvel Salvador');
    expect(honey.dy, greaterThan(aivan.dy), reason: 'Honey Salvador stacks below Aivan Salvador');
    expect(daniel.dy, greaterThan(honey.dy), reason: 'Daniel Salvador stacks below Honey Salvador');

    // Branch columns sit left→right in data order.
    expect(
      hanna.dx,
      lessThan(jongjong.dx),
      reason: 'Gernan column left of Rodel Sr. column',
    );
    expect(
      jongjong.dx,
      lessThan(arvel.dx),
      reason: 'Rodel Sr. column left of Lorie column',
    );

    // No layout overflow in the grid.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mga Apo cards render at narrow width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
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

    await tester.scrollUntilVisible(
      find.text('8 miyembro'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('data groups grandchildren by parent', (tester) async {
    final apoGroup = FamilyController.data.groups.firstWhere(
      (g) => g.labelKey == 'family_group_grandchildren',
    );
    final byParent = <String, List<FamilyMember>>{};
    for (final m in apoGroup.members) {
      byParent.putIfAbsent(m.parentName ?? '', () => []).add(m);
    }
    expect(byParent['Gernan Lumbao']!.map((m) => m.name).toList(), [
      'Hanna Lumbao',
      'Audrey Lumbao',
    ]);
    expect(byParent['Rodel Lumbao Sr.']!.map((m) => m.name).toList(), [
      'Rodel Lumbao Jr.',
      'Rose-ann Lumbao',
    ]);
    expect(byParent['Lorie Salvador']!.map((m) => m.name).toList(), [
      'Arvel Salvador',
      'Aivan Salvador',
      'Honey Salvador',
      'Daniel Salvador',
    ]);
  });
}