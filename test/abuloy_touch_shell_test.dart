import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/controllers/words_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/settings/settings_page.dart';
import 'package:nita/widgets/abuloy_touch.dart';

/// The touch lives in the Home shell's stack (above the tab bodies), so it
/// must be present no matter which tab is showing — and its dialog must
/// open from a real tab, not just an isolated harness.
Widget _shell(int selectedTab) => HomeShell(
      selectedTab: selectedTab,
      onTabChanged: (_) {},
      homeController: HomeController(),
      galleryController: GalleryController(),
      wordsController: WordsController(),
      condolencesController: CondolencesController(),
      forumController: ForumController(),
    );

Future<void> _pumpShell(WidgetTester tester, int tab) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(home: _shell(tab)),
    ),
  );
  // Fixed pumps only: the gallery tab runs an indefinite slideshow timer
  // and the forum tab an indefinite spinner, so pumpAndSettle would hang.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    // Same as header_scroll_test: keeps VisibilityDetector timers from
    // failing teardown.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('AbuloyTouch across the Home shell', () {
    for (var tab = 0; tab < 5; tab++) {
      testWidgets('visible on tab $tab', (tester) async {
        await _pumpShell(tester, tab);
        expect(find.byType(AbuloyTouch), findsOneWidget);
      });
    }

    testWidgets('tap opens the dialog from the Story tab', (tester) async {
      await _pumpShell(tester, 0);
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pump(const Duration(milliseconds: 500));
      // Default language is Tagalog; the page section lives on tab 4, so
      // this title can only come from the dialog.
      expect(find.text('Abuloy para sa Pamilya'), findsOneWidget);
    });

    testWidgets('can be dragged up into the hero zone', (tester) async {
      // The touch floats over the whole body (not just the content strip),
      // so on the Story tab it must reach the memorial hero at the top.
      await _pumpShell(tester, 0);
      await tester.drag(find.byType(AbuloyTouch), const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 400));
      final pos = tester.widget<Positioned>(
        find.ancestor(
          of: find.byIcon(Icons.volunteer_activism_outlined),
          matching: find.byType(Positioned),
        ),
      );
      expect(pos.top, AbuloyTouch.margin);
    });

    testWidgets('visible and working on the Settings page', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AbuloyTouch), findsOneWidget);
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Abuloy para sa Pamilya'), findsOneWidget);
    });
  });
}
