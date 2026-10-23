import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/controllers/words_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/views/condolences/condolences_page.dart';
import 'package:nita/views/family/family_page.dart';
import 'package:nita/views/gallery/gallery_page.dart';
import 'package:nita/views/guide/guide_page.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/words/words_page.dart';
import 'package:nita/widgets/abuloy_touch.dart';
import 'package:nita/widgets/app_bottom_nav.dart';

void main() {
  setUpAll(() {
    // Keep VisibilityDetector's periodic timer out of widget tests.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('locks immediately and keeps the lock through the guide', (
    tester,
  ) async {
    final guide = GuideController();
    var starts = 0;
    guide.onStartGuide = (_) => starts++;
    addTearDown(guide.dispose);

    guide.maybeAutoStart('home');
    expect(guide.inputLocked, isTrue);
    expect(starts, 0, reason: 'the lock comes before the 1.5s delay');

    await tester.pump(const Duration(milliseconds: 1499));
    expect(guide.inputLocked, isTrue);
    expect(starts, 0);

    await tester.pump(const Duration(milliseconds: 2));
    expect(starts, 1);
    expect(
      guide.inputLocked,
      isTrue,
      reason: 'stays locked while the guide is up',
    );

    guide.onGuideFinished('home');
    await tester.pump();
    expect(guide.inputLocked, isFalse);
  });

  testWidgets('never locks a disabled guide, a seen tab, or a manual replay', (
    tester,
  ) async {
    final disabled = GuideController(guideEnabled: false);
    var starts = 0;
    disabled.onStartGuide = (_) => starts++;
    addTearDown(disabled.dispose);

    disabled.maybeAutoStart('home');
    expect(disabled.inputLocked, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(starts, 0);

    final seen = GuideController(seenGuides: {'gallery'});
    seen.onStartGuide = (_) => starts++;
    addTearDown(seen.dispose);

    seen.maybeAutoStart('gallery');
    expect(seen.inputLocked, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(starts, 0);

    final manual = GuideController(seenGuides: {'home'});
    manual.onStartGuide = (_) => starts++;
    addTearDown(manual.dispose);

    manual.startManually('home');
    expect(manual.inputLocked, isFalse);
    expect(starts, 1);
  });

  testWidgets('all five tabs lock during their first visit delay', (
    tester,
  ) async {
    for (final tab in const [
      'home',
      'gallery',
      'family',
      'tribute',
      'favorites',
    ]) {
      final guide = GuideController();
      guide.onStartGuide = (_) {};

      guide.setCurrentTab(tab);
      guide.maybeAutoStart(tab);
      expect(guide.inputLocked, isTrue, reason: '$tab should lock');

      guide.dispose();
    }
  });

  testWidgets('a tab change releases the lock and cancels the guide', (
    tester,
  ) async {
    final guide = GuideController();
    var starts = 0;
    guide.onStartGuide = (_) => starts++;
    addTearDown(guide.dispose);

    guide.maybeAutoStart('home');
    expect(guide.inputLocked, isTrue);

    guide.setCurrentTab('gallery');
    expect(guide.inputLocked, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(starts, 0, reason: 'the old delay must not open a guide');
  });

  testWidgets('a start error releases the lock', (tester) async {
    final guide = GuideController();
    guide.onStartGuide = (_) => throw StateError('guide failed');
    addTearDown(guide.dispose);

    guide.maybeAutoStart('home');
    expect(guide.inputLocked, isTrue);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(guide.inputLocked, isFalse);
  });

  testWidgets('the 8 second failsafe releases a lock with no visible guide', (
    tester,
  ) async {
    final guide = GuideController();
    guide.onStartGuide = (_) {};
    addTearDown(guide.dispose);

    guide.maybeAutoStart('home');
    expect(guide.inputLocked, isTrue);

    await tester.pump(const Duration(milliseconds: 1600));
    expect(guide.inputLocked, isTrue);

    await tester.pump(const Duration(milliseconds: 6500));
    expect(guide.inputLocked, isFalse);
  });

  group('HomeShell input lock', () {
    Widget app(
      GuideController guide, {
      required ValueChanged<int> onTabChanged,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
          ),
          ChangeNotifierProvider.value(value: guide),
        ],
        child: MaterialApp(
          home: HomeShell(
            selectedTab: 0,
            onTabChanged: onTabChanged,
            homeController: HomeController(),
            galleryController: GalleryController(),
            wordsController: WordsController(),
            condolencesController: CondolencesController(),
            forumController: ForumController(),
          ),
        ),
      );
    }

    Finder blocker() => find.byWidgetPredicate(
      (widget) => widget is AbsorbPointer && widget.absorbing,
    );

    testWidgets('blocks taps, nav, Abuloy, wheel and touch during the delay', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final guide = GuideController();
      final changes = <int>[];
      addTearDown(guide.dispose);

      await tester.pumpWidget(app(guide, onTabChanged: changes.add));
      // First frame + the shell's post-frame guide bookkeeping.
      await tester.pump();

      expect(guide.inputLocked, isTrue);
      expect(blocker(), findsOneWidget);
      final blockerWidget = tester.widget<AbsorbPointer>(blocker());
      expect((blockerWidget.child! as Container).color, Colors.transparent);

      // Bottom navigation.
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byIcon(Icons.photo_library_outlined),
        ),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(changes, isEmpty);

      // Top bar help (manual replay must not start under the lock).
      await tester.tap(
        find.byIcon(Icons.help_outline_rounded),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byType(GuidePage), findsNothing);

      // Floating Abuloy touch.
      await tester.tap(find.byType(AbuloyTouch), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Abuloy para sa Pamilya'), findsNothing);

      // Touch drag and mouse wheel.
      final story = find
          .descendant(
            of: find.byType(StoryPage),
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(story).position;
      expect(position.pixels, 0);
      await tester.drag(
        find.byType(StoryPage),
        const Offset(0, -300),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(position.pixels, 0, reason: 'touch drag is blocked');

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(StoryPage)),
          scrollDelta: const Offset(0, 400),
        ),
      );
      await tester.pump();
      expect(position.pixels, 0, reason: 'mouse wheel is blocked');

      final storyView = tester.widget<CustomScrollView>(
        find
            .descendant(
              of: find.byType(StoryPage),
              matching: find.byType(CustomScrollView),
            )
            .first,
      );
      expect(storyView.physics, isA<NeverScrollableScrollPhysics>());

      // Every mounted page's main scroll view is frozen, not just the
      // active one. (The gallery grid is covered by its own test below;
      // its page is a spinner until the image manifest resolves.)
      for (final page in const [FamilyPage, WordsPage, CondolencesPage]) {
        final view = tester.widget<ScrollView>(
          find
              .descendant(
                of: find.byType(page, skipOffstage: false),
                matching: find.byWidgetPredicate(
                  (widget) => widget is ScrollView,
                  skipOffstage: false,
                ),
                skipOffstage: false,
              )
              .first,
        );
        expect(
          view.physics,
          isA<NeverScrollableScrollPhysics>(),
          reason: '$page should be frozen',
        );
      }

      // The guide appears after the delay and remains locked.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuidePage), findsOneWidget);
      expect(guide.inputLocked, isTrue);

      // Skip releases the lock and restores normal scrolling.
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byType(GuidePage), findsNothing);
      expect(guide.inputLocked, isFalse);
      expect(blocker(), findsNothing);
      final restored = tester.widget<CustomScrollView>(
        find
            .descendant(
              of: find.byType(StoryPage),
              matching: find.byType(CustomScrollView),
            )
            .first,
      );
      expect(restored.physics, isA<ClampingScrollPhysics>());
      for (final page in const [FamilyPage, WordsPage, CondolencesPage]) {
        final view = tester.widget<ScrollView>(
          find
              .descendant(
                of: find.byType(page, skipOffstage: false),
                matching: find.byWidgetPredicate(
                  (widget) => widget is ScrollView,
                  skipOffstage: false,
                ),
                skipOffstage: false,
              )
              .first,
        );
        expect(
          view.physics,
          isNot(isA<NeverScrollableScrollPhysics>()),
          reason: '$page should scroll again',
        );
      }

      // The nav works again.
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byIcon(Icons.photo_library_outlined),
        ),
      );
      await tester.pump();
      expect(changes, contains(1));
    });

    testWidgets('the gallery grid freezes and thaws with the lock', (
      tester,
    ) async {
      final guide = GuideController()..lockInput();
      final gallery = GalleryController();
      final scroll = ScrollController();
      final activeTab = ValueNotifier<int>(1);
      addTearDown(() {
        guide.unlockInput();
        guide.dispose();
        gallery.dispose();
        scroll.dispose();
        activeTab.dispose();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  LanguageProvider()..setLanguage(AppLanguage.english),
            ),
            ChangeNotifierProvider.value(value: guide),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GalleryGridView(
                images: [
                  GalleryImageItem(
                    path: 'assets/images/Bahay.jpg',
                    group: GalleryGroup.bahay,
                  ),
                ],
                controller: scroll,
                activeTab: activeTab,
                galleryController: gallery,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final grid = find
          .descendant(
            of: find.byType(GalleryGridView),
            matching: find.byType(CustomScrollView),
          )
          .first;
      expect(
        tester.widget<CustomScrollView>(grid).physics,
        isA<NeverScrollableScrollPhysics>(),
      );

      guide.unlockInput();
      await tester.pump();
      expect(
        tester.widget<CustomScrollView>(grid).physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
    });

    testWidgets('Android back during the delay does not leave Home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final guide = GuideController();
      addTearDown(guide.dispose);

      await tester.pumpWidget(app(guide, onTabChanged: (_) {}));
      await tester.pump();
      expect(guide.inputLocked, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(HomeShell), findsOneWidget);
      expect(guide.inputLocked, isTrue);

      // Leave the delay through the tab-change path so the test ends with
      // no pending auto-start or failsafe timers.
      guide.setCurrentTab('gallery');
      await tester.pump();
      expect(guide.inputLocked, isFalse);
    });

    testWidgets('the ? replay opens immediately without a lock', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final guide = GuideController(seenGuides: {'home'});
      addTearDown(guide.dispose);

      await tester.pumpWidget(app(guide, onTabChanged: (_) {}));
      await tester.pump();
      expect(guide.inputLocked, isFalse);

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(guide.inputLocked, isFalse);
    });
  });
}
