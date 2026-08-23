import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';
import 'package:nita/widgets/ornamental_card.dart';

void main() {
  // Common phone widths — the family member grid must stay centered,
  // uniformly sized, and free of overflow on every one of these.
  const sizes = <double>[240, 280, 320, 360, 390, 412, 600, 800];

  for (final width in sizes) {
    testWidgets('family overflow probe @ ${width.toInt()}px', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
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

      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow/exception at ${width.toInt()}px width',
      );
    });
  }

  testWidgets('member cards are responsive and uniform', (
    WidgetTester tester,
  ) async {
    Finder cardOf(String name) => find
        .ancestor(of: find.text(name), matching: find.byType(OrnamentalCard))
        .first;

    Future<double> ramonWidth(double screenWidth) async {
      tester.view.physicalSize = Size(screenWidth, 844);
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
      return tester.getSize(cardOf('Gernan Lumbao')).width;
    }

    final narrow = await ramonWidth(390);
    final wide = await ramonWidth(800);
    expect(
      wide,
      greaterThan(narrow),
      reason: 'cards must widen with the screen (390px -> 800px)',
    );
    expect(
      wide,
      lessThanOrEqualTo(220),
      reason: 'cards must not exceed the 220px cap on wide screens',
    );

    // All three cards in a row must be the same width.
    await tester.pumpWidget(Container());
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(home: FamilyPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final ramon = tester.getSize(cardOf('Gernan Lumbao')).width;
    final rosario = tester.getSize(cardOf('Odin Lumbao')).width;
    expect(
      ramon,
      closeTo(rosario, 0.1),
      reason: 'all member cards must be the same width',
    );
  });
}
