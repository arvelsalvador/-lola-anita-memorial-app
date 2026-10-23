import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/controllers/words_controller.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/widgets/framed_memorial_portrait.dart';

void _noop(int _) {}

Widget _app(int selectedTab, {ValueChanged<int>? onTabChanged}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      // HomeShell registers its scroll controllers with the guide in a
      // post-frame callback, so the provider is required here. Auto-start is
      // disabled: these tests never open a tour, and the 1.5s auto-start
      // timer would otherwise push the guide over the hero mid-test.
      ChangeNotifierProvider(
        create: (_) => GuideController(guideEnabled: false),
      ),
    ],
    child: MaterialApp(
      home: HomeShell(
        selectedTab: selectedTab,
        onTabChanged: onTabChanged ?? _noop,
        homeController: HomeController(),
        galleryController: GalleryController(),
        wordsController: WordsController(),
        condolencesController: CondolencesController(),
      ),
    ),
  );
}

/// The hero's collapse container height — 0 means the hero is hidden, the
/// full expanded height means it is shown. Read after the fixed pumps so the
/// collapse animation has finished.
double _heroHeight(WidgetTester tester) => tester
    .getSize(find.byKey(const ValueKey('hero-collapse'), skipOffstage: false))
    .height;

/// The Story tab's current scroll offset.
double _storyPixels(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byType(StoryPage),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable.first).position.pixels;
}

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
    await tester.pumpWidget(_app(0));
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

  testWidgets('hero tracks the scroll 1:1 and never flaps mid-scroll', (
    tester,
  ) async {
    // The hero height is a pure function of the Story tab's scroll offset
    // ((expandedHeight - offset), clamped). The regression guarded against
    // here is any state that breaks that mapping — e.g. the hero popping
    // open mid-scroll and collapsing again ("flapping"), which used to
    // happen when a short page reported pixels=0 while the visible page
    // was still scrolled down.
    await tester.pumpWidget(_app(0));
    await tester.pump(const Duration(milliseconds: 400));

    // Mirrors the expandedHeight formula in _HomeShellState.build, read from
    // the real test viewport instead of a hardcoded guess.
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final expandedHeight = math.min(
      (viewportHeight * 0.50).clamp(460.0, 580.0),
      math.max(0.0, viewportHeight - 120),
    );

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
          reason:
              'hero height must track the scroll offset exactly '
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
  });

  testWidgets('hero only appears on the home tab', (tester) async {
    Future<void> pumpTab(int tab) async {
      await tester.pumpWidget(_app(tab));
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

  testWidgets('a drag starting on the hero scrolls the story', (tester) async {
    // Phone-sized viewport so the hero is the tall block a visitor actually
    // swipes on.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(0));
    await tester.pump(const Duration(milliseconds: 400));

    final heroRect = tester.getRect(
      find.byKey(const ValueKey('hero-collapse'), skipOffstage: false),
    );
    expect(heroRect.height, greaterThan(0));

    // Start inside the visible hero (below the top bar), then fling upward.
    // Before the fix this drag hit no scrollable at all and the story stayed
    // at offset 0.
    final start = Offset(heroRect.center.dx, heroRect.top + 100);
    await tester.dragFrom(start, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      _storyPixels(tester),
      greaterThan(0),
      reason: 'the drag on the hero must reach the Story scroll view',
    );
    expect(
      _heroHeight(tester),
      0,
      reason: 'the hero must collapse exactly as if the content was dragged',
    );
  });

  testWidgets('tapping the hero portrait still opens the gallery', (
    tester,
  ) async {
    int? openedTab;
    await tester.pumpWidget(_app(0, onTabChanged: (tab) => openedTab = tab));
    await tester.pump(const Duration(milliseconds: 400));

    // The new drag recognizer must not swallow the portrait's tap.
    await tester.tap(find.byType(FramedMemorialPortrait).first);
    await tester.pump();

    expect(openedTab, 1);
  });
}
