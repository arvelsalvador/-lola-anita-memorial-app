import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/data/guide/guide_repository.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/views/family/family_page.dart';
import 'package:nita/views/gallery/gallery_page.dart';
import 'package:nita/views/guide/guide_content.dart';
import 'package:nita/views/guide/guide_page.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/widgets/abuloy_touch.dart';
import 'package:nita/widgets/app_bottom_nav.dart';
import 'package:nita/widgets/app_brand_bar.dart';
import 'package:nita/widgets/language_toggle.dart';

void main() {
  setUpAll(() {
    // VisibilityDetector defers callbacks on a periodic timer that would
    // otherwise stay pending at teardown.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GuideRepository', () {
    test('seen flag starts false, round-trips, and resets', () async {
      const repo = GuideRepository();

      expect(await repo.hasSeen(), isFalse);

      await repo.markSeen();
      expect(await repo.hasSeen(), isTrue);

      await repo.reset();
      expect(await repo.hasSeen(), isFalse);
    });

    test('the Gallery flag is independent of the homepage flag', () async {
      const home = GuideRepository();
      const gallery = GuideRepository.gallery();

      await home.markSeen();
      expect(await home.hasSeen(), isTrue);
      expect(await gallery.hasSeen(), isFalse);

      await gallery.markSeen();
      expect(await gallery.hasSeen(), isTrue);

      await gallery.reset();
      expect(await gallery.hasSeen(), isFalse);
      expect(await home.hasSeen(), isTrue);
    });
  });

  group('guide copy', () {
    test('every guide key exists in en, tl, and bi', () {
      final keys = <String>{
        'guide_help_tooltip',
        'guide_settings_title',
        'guide_settings_desc',
        'guide_topbar_title',
        'guide_topbar_body',
        'guide_abuloy_title',
        'guide_abuloy_body',
        'guide_nav_title',
        'guide_nav_body',
        'guide_next',
        'guide_done',
        'guide_step',
        'guide_skip',
        'gallery_guide_search_title',
        'gallery_guide_search_body',
        'gallery_guide_pills_title',
        'gallery_guide_pills_body',
        'gallery_guide_featured_title',
        'gallery_guide_featured_body',
        'gallery_guide_done',
        'family_guide_member_title',
        'family_guide_member_body',
        'family_guide_done',
      };

      for (final entry in {
        'en': LanguageProvider.en,
        'tl': LanguageProvider.tl,
        'bi': LanguageProvider.bi,
      }.entries) {
        for (final key in keys) {
          expect(
            entry.value[key],
            isNotNull,
            reason: '${entry.key} is missing "$key"',
          );
        }
      }
    });

    test('the tour runs top bar, then Abuloy, then the bottom nav', () {
      expect(guideSteps, hasLength(3));

      expect(guideSteps[0].spotlight, GuideSpotlight.topBar);
      expect(guideSteps[0].art, GuideArt.wave);
      expect(guideSteps[0].titleKey, 'guide_topbar_title');
      expect(guideSteps[0].bodyKey, 'guide_topbar_body');

      expect(guideSteps[1].spotlight, GuideSpotlight.abuloy);
      expect(guideSteps[1].art, GuideArt.touchPhone);
      expect(guideSteps[1].titleKey, 'guide_abuloy_title');
      expect(guideSteps[1].bodyKey, 'guide_abuloy_body');

      expect(guideSteps[2].spotlight, GuideSpotlight.bottomNav);
      expect(guideSteps[2].art, GuideArt.pointUp);
      expect(guideSteps[2].titleKey, 'guide_nav_title');
      expect(guideSteps[2].bodyKey, 'guide_nav_body');

      for (final step in guideSteps) {
        expect(step.art.asset, contains('assets/images/vector/'));
      }
    });

    test('the Gallery tour ends on the playable featured slideshow', () {
      expect(galleryGuideSteps, hasLength(3));

      final search = galleryGuideSteps[0];
      expect(search.spotlight, GuideSpotlight.gallerySearchBar);
      expect(search.art, GuideArt.touchPhone);
      expect(search.titleKey, 'gallery_guide_search_title');
      expect(search.bodyKey, 'gallery_guide_search_body');

      final pills = galleryGuideSteps[1];
      expect(pills.spotlight, GuideSpotlight.galleryFilterPills);
      expect(pills.art, GuideArt.pointUp);
      expect(pills.titleKey, 'gallery_guide_pills_title');
      expect(pills.bodyKey, 'gallery_guide_pills_body');

      final featured = galleryGuideSteps[2];
      expect(featured.spotlight, GuideSpotlight.galleryFeaturedCard);
      expect(featured.art, GuideArt.heart);
      expect(featured.titleKey, 'gallery_guide_featured_title');
      expect(featured.bodyKey, 'gallery_guide_featured_body');

      for (final step in galleryGuideSteps) {
        expect(step.art.asset, contains('assets/images/vector/'));
      }
    });

    test('the Family tour is a single member-card hint', () {
      expect(familyGuideSteps, hasLength(1));

      final member = familyGuideSteps.single;
      expect(member.spotlight, GuideSpotlight.familyMember);
      expect(member.art, GuideArt.pointUp);
      expect(member.titleKey, 'family_guide_member_title');
      expect(member.bodyKey, 'family_guide_member_body');
      expect(member.art.asset, contains('assets/images/vector/'));
    });

    test('the top-bar ? picks the tour for the tab that is open', () {
      expect(GuidePage.tourForTab(0), GuideTour.home);
      expect(GuidePage.tourForTab(1), GuideTour.gallery);
      expect(GuidePage.tourForTab(2), GuideTour.family);
      expect(GuidePage.tourForTab(3), GuideTour.home);
      expect(GuidePage.tourForTab(4), GuideTour.home);
    });
  });

  group('GuidePage', () {
    Widget app(LanguageProvider lang) => ChangeNotifierProvider.value(
      value: lang,
      child: const MaterialApp(home: GuidePage()),
    );

    testWidgets('opens on the top-bar stop with the bar lit', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();

      expect(find.text('Meet the top bar'), findsOneWidget);
      expect(find.textContaining('language button'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byType(AppBrandBar), findsOneWidget);
      expect(find.byType(LanguageToggle), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(find.byType(Image), findsWidgets);
      expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Next')).height,
        greaterThanOrEqualTo(56),
        reason: 'guide actions should be at least 56px tall',
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Skip')).height,
        greaterThanOrEqualTo(56),
        reason: 'Skip should be at least 56px tall',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Next walks top bar, Abuloy, nav, then finishes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Abuloy, always within reach'), findsOneWidget);
      expect(find.textContaining('Tap the gold button'), findsOneWidget);
      expect(find.byType(AbuloyTouchVisual), findsOneWidget);
      expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(find.byType(AppBrandBar), findsNothing);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Meet your navigation bar'), findsOneWidget);
      expect(find.textContaining('Tap any tab'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(AbuloyTouchVisual), findsNothing);
      expect(find.byType(AppBrandBar), findsNothing);
      expect(find.text('Start exploring'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Start exploring'));
      await tester.pump();

      expect(await const GuideRepository().hasSeen(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Abuloy stop lights the coin at its real dock', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();

      final el = tester.element(find.byType(AbuloyTouchVisual));
      final size = MediaQuery.sizeOf(el);
      final padding = MediaQuery.paddingOf(el);
      final topLeft = tester.getTopLeft(find.byType(AbuloyTouchVisual));

      // Same dock as the live touch: right 20, above the nav (bottom 104).
      expect(topLeft.dx, closeTo(size.width - 20 - AbuloyTouch.size, 0.001));
      expect(
        topLeft.dy,
        closeTo(size.height - padding.bottom - 104 - AbuloyTouch.size, 0.001),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Skip marks the guide seen from the first stop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(await const GuideRepository().hasSeen(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('system back steps back, then closes the guide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GuidePage()),
                    ),
                    child: const Text('Open guide'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open guide'));
      await tester.pumpAndSettle();
      expect(find.text('Meet the top bar'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Abuloy, always within reach'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Meet your navigation bar'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      // Back on the nav stop returns to the Abuloy stop.
      await navigator.maybePop();
      await tester.pump();
      expect(find.text('Abuloy, always within reach'), findsOneWidget);
      expect(find.text('Meet your navigation bar'), findsNothing);

      // Back again returns to the top-bar stop.
      await navigator.maybePop();
      await tester.pump();
      expect(find.text('Meet the top bar'), findsOneWidget);
      expect(find.text('Abuloy, always within reach'), findsNothing);

      // Back on the first stop closes the guide.
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(GuidePage), findsNothing);
      expect(await const GuideRepository().hasSeen(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dims the app with a translucent scrim', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();

      final scrim = tester.widget<ColoredBox>(find.byKey(GuidePage.scrimKey));
      expect(scrim.color.a, GuidePage.scrimOpacity);
      expect(scrim.color.a, lessThan(1.0));
      expect(scrim.color.a, greaterThanOrEqualTo(0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the top bar shows the visitor greeting', (tester) async {
      SharedPreferences.setMockInitialValues({'visitor_name': 'Maria Santos'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(LanguageProvider()));
      await tester.pump();
      await tester.pump();

      expect(find.text('Kumusta, Maria'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the language pill works from inside the guide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(app(lang));
      await tester.pump();
      expect(find.text('Meet the top bar'), findsOneWidget);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();
      expect(find.text('Tagalog'), findsOneWidget);

      await tester.tap(find.text('Tagalog'));
      await tester.pumpAndSettle();

      expect(find.text('Kilalanin ang bar sa itaas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all three stops fit phones, desktop, and landscape', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      void expectActionVisible(String step) {
        final rect = tester.getRect(find.byType(FilledButton));
        expect(
          rect.top,
          greaterThanOrEqualTo(0),
          reason: '$step action should start on-screen',
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height),
          reason: '$step action should end on-screen',
        );
      }

      for (final size in const [
        Size(360, 640),
        Size(390, 844),
        Size(1280, 800),
        Size(640, 360),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final lang = LanguageProvider()..setLanguage(AppLanguage.english);
        await tester.pumpWidget(app(lang));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'top bar should fit ${size.width}x${size.height}',
        );
        expectActionVisible('top bar');

        await tester.ensureVisible(find.text('Next'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Abuloy should fit ${size.width}x${size.height}',
        );
        expectActionVisible('Abuloy');

        await tester.ensureVisible(find.text('Next'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'nav should fit ${size.width}x${size.height}',
        );
        expectActionVisible('nav');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('renders Tagalog and Bicol on a small phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(LanguageProvider()));
      await tester.pump();
      expect(find.text('Kilalanin ang bar sa itaas'), findsOneWidget);

      await tester.tap(find.text('Susunod'));
      await tester.pump();
      expect(find.text('Abuloy, laging abot-kamay'), findsOneWidget);

      await tester.tap(find.text('Susunod'));
      await tester.pump();
      expect(find.text('Kilalanin ang bar sa ibaba'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Dispose the Tagalog guide so the Bicol pass starts on step one again.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final bicol = LanguageProvider()..setLanguage(AppLanguage.bicol);
      await tester.pumpWidget(app(bicol));
      await tester.pump();
      expect(find.text('Bistohon an bar sa itaas'), findsOneWidget);

      await tester.tap(find.text('Sunod'));
      await tester.pump();
      expect(find.text('Abuloy, yaon sa kamot'), findsOneWidget);

      await tester.tap(find.text('Sunod'));
      await tester.pump();
      expect(find.text('Bistohon an bar sa ibaba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Gallery tour lights search, pills, then the slideshow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final featured = ValueNotifier<Rect?>(
        const Rect.fromLTWH(16, 290, 358, 128),
      );
      addTearDown(featured.dispose);
      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: GuidePage(
              tour: GuideTour.gallery,
              searchBarRect: const Rect.fromLTWH(16, 150, 358, 46),
              filterPillsRect: const Rect.fromLTWH(16, 216, 358, 48),
              featuredCardRect: featured,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Search the memories'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Got it'), findsNothing);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.byKey(GuidePage.gallerySearchOutlineKey), findsOneWidget);
      expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
      // No homepage chrome is rebuilt on the Gallery tour.
      expect(find.byType(AppBrandBar), findsNothing);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Filter the memories'), findsOneWidget);
      expect(find.textContaining('Last Day'), findsOneWidget);
      expect(find.text('Got it'), findsNothing);
      expect(find.byKey(GuidePage.galleryPillsOutlineKey), findsOneWidget);
      expect(find.byKey(GuidePage.gallerySearchOutlineKey), findsNothing);
      expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Play the memories'), findsOneWidget);
      expect(find.textContaining('slideshow'), findsOneWidget);
      expect(find.textContaining('music'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.byKey(GuidePage.galleryFeaturedOutlineKey), findsOneWidget);
      expect(find.byKey(GuidePage.galleryPillsOutlineKey), findsNothing);
      expect(find.bySemanticsLabel('Step 3 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Got it'));
      await tester.pump();

      expect(await const GuideRepository.gallery().hasSeen(), isTrue);
      expect(
        await const GuideRepository().hasSeen(),
        isFalse,
        reason: 'finishing the Gallery tip must not consume the home tour',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the pills stop asks the Gallery to reveal Huling Araw', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var reveals = 0;
      final lang = LanguageProvider()..setLanguage(AppLanguage.english);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: GuidePage(
              tour: GuideTour.gallery,
              searchBarRect: const Rect.fromLTWH(16, 150, 358, 46),
              filterPillsRect: const Rect.fromLTWH(16, 216, 358, 48),
              onFilterPillsShown: () => reveals++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(reveals, 0, reason: 'the search stop leaves the row alone');

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(reveals, 1);

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navigator.maybePop();
      await tester.pump();
      expect(find.text('Search the memories'), findsOneWidget);
      expect(reveals, 1, reason: 'going back to search must not re-scroll');

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(reveals, 2, reason: 'returning to the pills reveals them again');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the pills stop rings the gold Huling Araw pill', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final hulingAraw = ValueNotifier<Rect?>(null);
      addTearDown(hulingAraw.dispose);
      final lang = LanguageProvider()..setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: GuidePage(
              tour: GuideTour.gallery,
              searchBarRect: const Rect.fromLTWH(16, 150, 358, 46),
              filterPillsRect: const Rect.fromLTWH(16, 216, 358, 48),
              hulingArawRect: hulingAraw,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(GuidePage.galleryHulingArawOutlineKey),
        findsNothing,
        reason: 'only the pills stop rings the gold pill',
      );

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.byKey(GuidePage.galleryPillsOutlineKey), findsOneWidget);
      expect(
        find.byKey(GuidePage.galleryHulingArawOutlineKey),
        findsNothing,
        reason: 'the Gallery has not reported the pill yet',
      );

      hulingAraw.value = const Rect.fromLTWH(280, 222, 90, 36);
      await tester.pump();
      expect(find.byKey(GuidePage.galleryHulingArawOutlineKey), findsOneWidget);
      final ring = tester.getRect(
        find.byKey(GuidePage.galleryHulingArawOutlineKey),
      );
      expect(ring.center.dx, closeTo(325, 1));
      expect(ring.center.dy, closeTo(240, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the featured stop lights the card once it is measured', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final featured = ValueNotifier<Rect?>(null);
      addTearDown(featured.dispose);
      var reveals = 0;
      final lang = LanguageProvider()..setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: GuidePage(
              tour: GuideTour.gallery,
              searchBarRect: const Rect.fromLTWH(16, 150, 358, 46),
              filterPillsRect: const Rect.fromLTWH(16, 216, 358, 48),
              featuredCardRect: featured,
              onFeaturedCardShown: () => reveals++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(reveals, 0, reason: 'the search stop leaves the card alone');

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(reveals, 0, reason: 'the pills stop leaves the card alone');

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(reveals, 1);
      expect(find.text('Play the memories'), findsOneWidget);
      expect(
        find.byKey(GuidePage.galleryFeaturedOutlineKey),
        findsNothing,
        reason: 'the Gallery has not measured the card yet',
      );
      // Without a rect the step still explains the card via the fallback.
      expect(find.byKey(GuidePage.scrimKey), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      featured.value = const Rect.fromLTWH(16, 120, 358, 128);
      await tester.pump();
      expect(find.byKey(GuidePage.galleryFeaturedOutlineKey), findsOneWidget);
      final outline = tester.getRect(
        find.byKey(GuidePage.galleryFeaturedOutlineKey),
      );
      expect(outline.center.dx, closeTo(195, 1));
      expect(outline.center.dy, closeTo(184, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Gallery stop fits phones, desktop, and landscape', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      for (final size in const [
        Size(360, 640),
        Size(390, 844),
        Size(1280, 800),
        Size(640, 360),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final lang = LanguageProvider()..setLanguage(AppLanguage.english);
        final searchRect = Rect.fromLTWH(
          16,
          size.height * 0.18,
          size.width - 32,
          46,
        );
        final pillsRect = Rect.fromLTWH(
          16,
          size.height * 0.34,
          size.width - 32,
          48,
        );
        final featuredRect = ValueNotifier<Rect?>(
          Rect.fromLTWH(16, 8, size.width - 32, 120),
        );
        addTearDown(featuredRect.dispose);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: lang,
            child: MaterialApp(
              home: GuidePage(
                tour: GuideTour.gallery,
                searchBarRect: searchRect,
                filterPillsRect: pillsRect,
                featuredCardRect: featuredRect,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Gallery search stop should fit ${size.width}x${size.height}',
        );
        var action = tester.getRect(find.byType(FilledButton));
        expect(
          action.top,
          greaterThanOrEqualTo(0),
          reason: 'Next should start on-screen at $size',
        );
        expect(
          action.bottom,
          lessThanOrEqualTo(size.height),
          reason: 'Next should end on-screen at $size',
        );

        // The pills stop sits lower on the screen, leaving less room below.
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Gallery pills stop should fit ${size.width}x${size.height}',
        );
        action = tester.getRect(find.byType(FilledButton));
        expect(
          action.top,
          greaterThanOrEqualTo(0),
          reason: 'Got it should start on-screen at $size',
        );
        expect(
          action.bottom,
          lessThanOrEqualTo(size.height),
          reason: 'Got it should end on-screen at $size',
        );

        // The featured-slideshow stop, lower still.
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Gallery featured stop should fit ${size.width}x'
              '${size.height}',
        );
        action = tester.getRect(find.byType(FilledButton));
        expect(
          action.top,
          greaterThanOrEqualTo(0),
          reason: 'Got it should start on-screen at $size',
        );
        expect(
          action.bottom,
          lessThanOrEqualTo(size.height),
          reason: 'Got it should end on-screen at $size',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('the Family tour lights one member card', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final memberRect = ValueNotifier<Rect?>(
        const Rect.fromLTWH(16, 260, 110, 170),
      );
      addTearDown(memberRect.dispose);
      final lang = LanguageProvider()..setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: GuidePage(
              tour: GuideTour.family,
              familyMemberRect: memberRect,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tap a family member'), findsOneWidget);
      expect(find.textContaining('personal information'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.bySemanticsLabel('Step 1 of 1'), findsOneWidget);
      expect(find.byKey(GuidePage.familyMemberOutlineKey), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Got it'));
      await tester.pump();

      expect(await const GuideRepository.family().hasSeen(), isTrue);
      expect(
        await const GuideRepository().hasSeen(),
        isFalse,
        reason: 'the Family tip is its own flag',
      );
      expect(
        await const GuideRepository.gallery().hasSeen(),
        isFalse,
        reason: 'the Family tip must not consume the Gallery tour',
      );
    });
  });

  group('first-run trigger', () {
    Widget homeApp() => ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MaterialApp(home: HomePage()),
    );

    testWidgets('a remembered visitor gets the top bar first', (tester) async {
      SharedPreferences.setMockInitialValues({
        'visitor_name': 'Test Visitor',
        'visitor_address': 'Daet, Camarines Norte',
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(homeApp());
      // Gate check -> Home, then the guide check -> push.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(HomePage, skipOffstage: false),
        findsOneWidget,
        reason: 'Home stays mounted under the guide route',
      );
      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Kilalanin ang bar sa itaas'), findsOneWidget);

      final guideRoute = ModalRoute.of(tester.element(find.byType(GuidePage)));
      expect(
        guideRoute!.opaque,
        isFalse,
        reason: 'Home must stay visible behind the translucent scrim',
      );

      await tester.tap(find.text('Susunod'));
      await tester.pump();
      expect(find.text('Abuloy, laging abot-kamay'), findsOneWidget);

      await tester.tap(find.text('Susunod'));
      await tester.pump();
      expect(find.text('Kilalanin ang bar sa ibaba'), findsOneWidget);

      await tester.tap(find.text('Simulan na'));
      await tester.pump();
      // Let the non-opaque guide route finish its pop transition.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a visitor who has seen the guide lands on Home', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'visitor_name': 'Test Visitor',
        'visitor_address': 'Daet, Camarines Norte',
        'guide_seen_v4': true,
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(homeApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the top-bar help button reopens the guide', (tester) async {
      SharedPreferences.setMockInitialValues({
        'visitor_name': 'Test Visitor',
        'visitor_address': 'Daet, Camarines Norte',
        'guide_seen_v4': true,
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(homeApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuidePage), findsNothing);

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Kilalanin ang bar sa itaas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('family first-open trigger', () {
    Widget familyHarness(
      ValueNotifier<int> tab, {
      ValueNotifier<int>? requests,
    }) => ChangeNotifierProvider(
      create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
      child: MaterialApp(
        home: Scaffold(
          body: FamilyPage(activeTab: tab, guideRequests: requests),
        ),
      ),
    );

    testWidgets('opens once when the Family tab becomes active', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(0);
      addTearDown(tab.dispose);

      await tester.pumpWidget(familyHarness(tab));
      await tester.pump();
      expect(find.byType(GuidePage), findsNothing);

      tab.value = 2;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Tap a family member'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(
        find.byKey(GuidePage.familyMemberOutlineKey),
        findsOneWidget,
        reason: 'the member card is measured and lit',
      );

      // The hole sits on the first member card.
      final outline = tester.getRect(
        find.byKey(GuidePage.familyMemberOutlineKey),
      );
      final firstName = tester.getRect(find.text('Roberto Daiz'));
      expect(outline.contains(firstName.center), isTrue);

      await tester.tap(find.text('Got it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(await const GuideRepository.family().hasSeen(), isTrue);
      expect(
        await const GuideRepository().hasSeen(),
        isFalse,
        reason: 'the Family tip is its own flag',
      );
      expect(
        await const GuideRepository.gallery().hasSeen(),
        isFalse,
        reason: 'the Family tip must not consume the Gallery tour',
      );

      // Leaving and reopening the tab must not show it again.
      tab.value = 0;
      await tester.pump();
      tab.value = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls the member card into view on a short screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(2);
      addTearDown(tab.dispose);

      await tester.pumpWidget(familyHarness(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.byKey(GuidePage.familyMemberOutlineKey), findsOneWidget);

      final page = find
          .descendant(
            of: find.byType(FamilyPage),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      final position = tester.state<ScrollableState>(page).position;
      expect(
        position.pixels,
        greaterThan(0),
        reason: 'the card is brought up so the bubble fits below it',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays away when the Family tip was already seen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'family_guide_seen_v2': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(2);
      addTearDown(tab.dispose);

      await tester.pumpWidget(familyHarness(tab));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ? replay reopens the Family tour', (tester) async {
      SharedPreferences.setMockInitialValues({'family_guide_seen_v2': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(2);
      final requests = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      addTearDown(requests.dispose);

      await tester.pumpWidget(familyHarness(tab, requests: requests));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(GuidePage),
        findsNothing,
        reason: 'the seen flag keeps the auto-open quiet',
      );

      requests.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Tap a family member'), findsOneWidget);
      expect(find.byKey(GuidePage.familyMemberOutlineKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('gallery first-open trigger', () {
    Widget galleryHarness(
      ValueNotifier<int> tab, {
      List<GalleryImageItem> images = const [],
      ValueNotifier<int>? requests,
    }) => ChangeNotifierProvider(
      create: (_) => LanguageProvider()..setLanguage(AppLanguage.english),
      child: MaterialApp(
        home: Scaffold(
          body: GalleryGridView(
            images: images,
            activeTab: tab,
            guideRequests: requests,
            galleryController: GalleryController(),
          ),
        ),
      ),
    );

    testWidgets('opens once when the Gallery tab becomes active', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(0);
      addTearDown(tab.dispose);

      await tester.pumpWidget(galleryHarness(tab));
      await tester.pump();
      expect(find.byType(GuidePage), findsNothing);

      tab.value = 1;
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Search the memories'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Filter the memories'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Play the memories'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(await const GuideRepository.gallery().hasSeen(), isTrue);
      expect(
        await const GuideRepository().hasSeen(),
        isFalse,
        reason: 'the Gallery tip is its own flag',
      );

      // Leaving and reopening the tab must not show it again.
      tab.value = 0;
      await tester.pump();
      tab.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays away when the Gallery tip was already seen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'gallery_guide_seen_v2': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(1);
      addTearDown(tab.dispose);

      await tester.pumpWidget(galleryHarness(tab));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('the pills stop scrolls the gold Huling Araw pill into view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // One photo per group makes the row overflow, as it does on a phone,
      // so the reveal has somewhere to scroll. The errorBuilder in the grid
      // covers the missing placeholder files.
      final images = [
        for (final group in GalleryGroup.values)
          GalleryImageItem(
            // Unique paths keep the grid's Hero tags unique; the files do not
            // exist, and the grid's errorBuilder renders a placeholder.
            path: 'assets/images/gallery/missing_${group.name}.jpg',
            group: group,
          ),
      ];

      final tab = ValueNotifier<int>(1);
      addTearDown(tab.dispose);

      await tester.pumpWidget(galleryHarness(tab, images: images));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Search the memories'), findsOneWidget);

      final pillsList = find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.horizontal,
        skipOffstage: false,
      );
      expect(pillsList, findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: pillsList,
          matching: find.byType(Scrollable, skipOffstage: false),
          skipOffstage: false,
        ),
      );
      expect(scrollable.position.pixels, 0);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(
        scrollable.position.pixels,
        greaterThan(0),
        reason: 'the row should slide so Huling Araw is under the cut-out',
      );
      final lastDay = find.text('Last Day', skipOffstage: false);
      expect(lastDay, findsOneWidget);
      final lastDayRect = tester.getRect(lastDay);
      final rowRect = tester.getRect(pillsList);
      expect(
        lastDayRect.left,
        greaterThanOrEqualTo(rowRect.left),
        reason: 'Huling Araw should be inside the row viewport',
      );
      expect(
        lastDayRect.right,
        lessThanOrEqualTo(rowRect.right),
        reason: 'Huling Araw should be fully inside the row viewport',
      );
      // The gold pill is ringed inside the lit row, so the copy's "the gold
      // Last Day pill" has a visible target.
      final ringFinder = find.byKey(
        GuidePage.galleryHulingArawOutlineKey,
        skipOffstage: false,
      );
      expect(ringFinder, findsOneWidget);
      final ring = tester.getRect(ringFinder);
      expect(ring.contains(lastDayRect.center), isTrue);
      expect(find.text('Filter the memories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ? replay reopens the tour at the search bar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'gallery_guide_seen_v2': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tab = ValueNotifier<int>(1);
      final requests = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      addTearDown(requests.dispose);

      await tester.pumpWidget(galleryHarness(tab, requests: requests));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(GuidePage),
        findsNothing,
        reason: 'the seen flag keeps the auto-open quiet',
      );

      requests.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.text('Search the memories'), findsOneWidget);
      expect(find.byKey(GuidePage.gallerySearchOutlineKey), findsOneWidget);
      expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the search stop brings a scrolled Gallery back to the bar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'gallery_guide_seen_v2': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Enough cards to make the grid scroll far below the search bar.
      final images = [
        for (var i = 0; i < 14; i++)
          GalleryImageItem(
            path: 'assets/images/gallery/missing_$i.jpg',
            group: GalleryGroup.family,
          ),
      ];
      final tab = ValueNotifier<int>(1);
      final requests = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      addTearDown(requests.dispose);

      await tester.pumpWidget(
        galleryHarness(tab, images: images, requests: requests),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final grid = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      final position = tester.state<ScrollableState>(grid).position;
      position.jumpTo(600);
      await tester.pump();
      expect(position.pixels, greaterThan(0));

      requests.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        position.pixels,
        0,
        reason: 'the first stop has to be on screen before it is lit',
      );
      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.byKey(GuidePage.gallerySearchOutlineKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the featured stop scrolls the card up on a short screen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'gallery_guide_seen_v2': true});
      // Small phone in landscape: the card is on screen but leaves little
      // room for the guide bubble, so the stop scrolls it up first.
      tester.view.physicalSize = const Size(390, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final images = [
        for (var i = 0; i < 6; i++)
          GalleryImageItem(
            path: 'assets/images/gallery/missing_$i.jpg',
            group: GalleryGroup.family,
          ),
      ];
      final tab = ValueNotifier<int>(1);
      final requests = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      addTearDown(requests.dispose);

      await tester.pumpWidget(
        galleryHarness(tab, images: images, requests: requests),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      requests.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Search the memories'), findsOneWidget);

      final grid = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      final position = tester.state<ScrollableState>(grid).position;
      expect(position.pixels, 0);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Play the memories'), findsOneWidget);
      expect(
        position.pixels,
        greaterThan(0),
        reason: 'the card should be scrolled up so the bubble fits',
      );
      expect(find.byKey(GuidePage.galleryFeaturedOutlineKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
