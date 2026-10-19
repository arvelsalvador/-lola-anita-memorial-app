import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/guide/guide_repository.dart';
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
        expect(step.art.asset, contains('assets/images/Vector/'));
      }
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
}
