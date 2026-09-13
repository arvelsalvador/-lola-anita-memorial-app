import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/memories_controller.dart';
import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/views/home_page.dart';

void _noop(int _) {}

Widget _shell(int selectedTab) => HomeShell(
  selectedTab: selectedTab,
  onTabChanged: _noop,
  memoriesController: MemoriesController(),
  galleryController: GalleryController(),
  tributeController: TributeController(),
);

/// The hero's collapse container height — 0 means the hero is hidden, the
/// full expanded height means it is shown. Read after the fixed pumps so the
/// collapse animation has finished.
double _heroHeight(WidgetTester tester) => tester
    .getSize(find.byKey(const ValueKey('hero-collapse'), skipOffstage: false))
    .height;

void main() {
  setUpAll(() {
    // VisibilityDetector defers its callbacks on a periodic timer, which
    // otherwise stays pending at teardown and fails the test with
    // "A Timer is still pending even after the widget tree was disposed."
    // (See the package README's "Widget tests" section.)
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('hero hides on scroll and only returns at the top', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(home: _shell(0)),
      ),
    );
    // Fixed pumps: the gallery tab shows an indefinite spinner, so
    // pumpAndSettle would never settle.
    await tester.pump(const Duration(milliseconds: 400));

    // At rest the hero is fully expanded, below the fixed top bar.
    final brandBefore = tester.getTopLeft(find.text('nanay anita')).dy;
    final heroTopBefore = tester
        .getTopLeft(find.byType(LolaHeroHeader, skipOffstage: false))
        .dy;
    expect(_heroHeight(tester), greaterThan(0));
    expect(heroTopBefore, greaterThan(brandBefore));

    // Scroll down a lot, from a spot that is not covered by the floating
    // bottom navigation.
    await tester.dragFrom(const Offset(100, 520), const Offset(0, -1200));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // The hero collapsed to nothing...
    expect(_heroHeight(tester), 0);

    // ...while the top bar stays exactly where it was.
    expect(tester.getTopLeft(find.text('nanay anita')).dy, brandBefore);

    // Scrolling back up a little must NOT bring the hero back.
    await tester.dragFrom(const Offset(100, 520), const Offset(0, 150));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_heroHeight(tester), 0);
    expect(tester.getTopLeft(find.text('nanay anita')).dy, brandBefore);

    // Only once the scroll is back near the very top does the hero return.
    await tester.dragFrom(const Offset(100, 520), const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_heroHeight(tester), greaterThan(0));
    expect(tester.getTopLeft(find.text('nanay anita')).dy, brandBefore);
  });

  testWidgets(
    'hero tracks the scroll 1:1 and never flaps mid-scroll',
    (tester) async {
      // The hero height is a pure function of the Story tab's scroll offset
      // ((expandedHeight - offset), clamped). The regression guarded against
      // here is any state that breaks that mapping — e.g. the hero popping
      // open mid-scroll and collapsing again ("flapping"), which used to
      // happen when a short page reported pixels=0 while the visible page
      // was still scrolled down.
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(home: _shell(0)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Viewport is 390x844, so this matches the expandedHeight formula in
      // _HomeShellState.build.
      const viewportHeight = 844.0;
      final expandedHeight = (viewportHeight * 0.46).clamp(400.0, 540.0);

      // The visible (Story) page's scroll offset.
      double storyPixels() {
        final f = find.descendant(
          of: find.byType(StoryPage),
          matching: find.byType(Scrollable),
        );
        return tester.state<ScrollableState>(f.first).position.pixels;
      }

      // Scroll down a lot so the hero fully collapses.
      await tester.dragFrom(const Offset(100, 520), const Offset(0, -1200));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_heroHeight(tester), 0);

      // Scroll back up in steps, sampling every frame. At every instant the
      // hero height must equal the offset mapping — it may grow smoothly as
      // the page nears the top, but it must never pop open and re-collapse.
      for (int i = 0; i < 4; i++) {
        await tester.dragFrom(const Offset(100, 520), const Offset(0, 300));
        for (int j = 0; j < 5; j++) {
          await tester.pump(const Duration(milliseconds: 50));
          final pixels = storyPixels();
          final expected = (expandedHeight - pixels).clamp(0.0, expandedHeight);
          expect(
            _heroHeight(tester),
            closeTo(expected, 1.0),
            reason: 'hero height must track the scroll offset exactly '
                '(no flapping) at step $i, frame $j, offset $pixels',
          );
        }
      }

      // Once the page reaches the very top the hero is fully expanded.
      await tester.dragFrom(const Offset(100, 520), const Offset(0, 2000));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(storyPixels(), lessThanOrEqualTo(1.0));
      expect(_heroHeight(tester), greaterThan(0));
    },
  );

  testWidgets('hero only appears on the home tab', (tester) async {
    Future<void> pumpTab(int tab) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: MaterialApp(home: _shell(tab)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Home tab: hero fully expanded.
    await pumpTab(0);
    expect(_heroHeight(tester), greaterThan(0));

    // Every other tab: hero collapsed to zero height.
    for (var tab = 1; tab <= 4; tab++) {
      await pumpTab(tab);
      expect(_heroHeight(tester), 0, reason: 'hero must be hidden on tab $tab');
    }

    // And back home it expands again.
    await pumpTab(0);
    expect(_heroHeight(tester), greaterThan(0));
  });
}
