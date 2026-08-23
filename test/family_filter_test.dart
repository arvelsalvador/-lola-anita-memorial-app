import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/family_page.dart';

// The selected pill's fill — read from the app palette so this test can't
// drift when the theme token changes.
const Color _activeOrange = AppColors.terracotta;

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

  // The filter chips live inside a Wrap (the same labels also appear in the
  // section headers further down the page, so scope by the Wrap).
  Finder chipText(String label, {bool skipOffstage = true}) => find.descendant(
    of: find.byType(Wrap, skipOffstage: skipOffstage),
    matching: find.text(label, skipOffstage: skipOffstage),
    skipOffstage: skipOffstage,
  );

  double pixels(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .pixels;

  // Pills scroll off-screen when a section is in view, so inspect the tree
  // including off-screen widgets (they stay mounted thanks to cacheExtent).
  Color? pillFill(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: chipText(label, skipOffstage: false),
            matching: find.byType(Container, skipOffstage: false),
          )
          .first,
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  testWidgets('filter tabs scroll to their sections', (tester) async {
    await pumpFamilyPage(tester);
    expect(pixels(tester), 0);

    // "Mga Apo" chip → smooth-scrolls to the grandchildren section. It is
    // the last section on a tall page, so the scroll clamps at the bottom;
    // the section header must end up fully visible on screen.
    await tester.tap(chipText('Mga Apo'));
    await tester.pumpAndSettle();
    final apoPixels = pixels(tester);
    expect(apoPixels, greaterThan(0));
    final apoHeaderTop = tester.getTopLeft(find.text('Mga Apo').last).dy;
    expect(apoHeaderTop, greaterThanOrEqualTo(0));
    expect(
      apoHeaderTop,
      lessThan(844),
      reason: 'the Apo section header should be visible on screen',
    );

    // "Lahat" chip → back to the very top.
    await tester.ensureVisible(chipText('Lahat', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(chipText('Lahat'));
    await tester.pumpAndSettle();
    expect(pixels(tester), 0);

    // "Direktang pamilya" chip → scrolls to the Mga Anak section (which sits
    // before the Apo section, so it must stop higher than the Apo scroll).
    await tester.tap(chipText('Direktang pamilya'));
    await tester.pumpAndSettle();
    final directPixels = pixels(tester);
    expect(directPixels, greaterThan(0));
    expect(directPixels, lessThan(apoPixels));
    final anakHeaderTop = tester.getTopLeft(find.text('Mga Anak')).dy;
    expect(anakHeaderTop, greaterThanOrEqualTo(0));
    expect(
      anakHeaderTop,
      lessThan(100),
      reason: 'the Mga Anak section header should sit near the viewport top',
    );
  });

  testWidgets('tapped tab keeps its active highlight', (tester) async {
    await pumpFamilyPage(tester);

    // "Lahat" starts selected.
    expect(pillFill(tester, 'Lahat'), _activeOrange);
    expect(pillFill(tester, 'Direktang pamilya'), Colors.white);

    await tester.tap(chipText('Mga Apo'));
    await tester.pumpAndSettle();
    expect(pillFill(tester, 'Mga Apo'), _activeOrange);
    expect(pillFill(tester, 'Lahat'), Colors.white);

    await tester.ensureVisible(
      chipText('Direktang pamilya', skipOffstage: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(chipText('Direktang pamilya'));
    await tester.pumpAndSettle();
    expect(pillFill(tester, 'Direktang pamilya'), _activeOrange);
    expect(pillFill(tester, 'Mga Apo'), Colors.white);

    await tester.ensureVisible(chipText('Lahat', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(chipText('Lahat'));
    await tester.pumpAndSettle();
    expect(pillFill(tester, 'Lahat'), _activeOrange);
  });

  testWidgets('active tab follows manual scrolling', (tester) async {
    await pumpFamilyPage(tester);
    expect(pillFill(tester, 'Lahat'), _activeOrange);

    // Scroll to the bottom: the Apo section is in view.
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(pillFill(tester, 'Mga Apo'), _activeOrange);

    // Scroll back to the top: "Lahat" becomes active again.
    await tester.drag(find.byType(ListView), const Offset(0, 2400));
    await tester.pumpAndSettle();
    expect(pillFill(tester, 'Lahat'), _activeOrange);
  });
}
