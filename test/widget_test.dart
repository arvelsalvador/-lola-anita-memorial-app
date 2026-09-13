import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/app.dart';
import 'package:nita/views/family_page.dart';
import 'package:nita/views/home_page.dart';
import 'package:nita/views/settings_page.dart';
import 'package:nita/views/splash_page.dart';
import 'package:nita/views/words_page.dart';
import 'package:nita/widgets/app_bottom_nav.dart';

void main() {
  setUpAll(() {
    // VisibilityDetector defers its callbacks on a periodic timer, which
    // otherwise stays pending at teardown and fails the test with
    // "A Timer is still pending even after the widget tree was disposed."
    // (See the package README's "Widget tests" section.)
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  // Nav taps must be scoped to the nav bar so the Family page's own title
  // doesn't make the label ambiguous.
  Finder navLabel(String text) =>
      find.descendant(of: find.byType(AppBottomNav), matching: find.text(text));

  // The Family tab is blank for now, so its title is scoped to the page.
  Finder familyTitle(String text) =>
      find.descendant(of: find.byType(FamilyPage), matching: find.text(text));

  // The hero header repeats the Story tab's quote, so quote assertions
  // must be scoped to the StoryPage body to stay unambiguous.
  Finder storyQuote(String text) => find.descendant(
    of: find.byType(StoryPage),
    matching: find.textContaining(text),
  );

  // The memory cards now live on the home (Story) tab, below the story
  // content — outside the test viewport. Sliver lists build lazily, so
  // scroll the Story page until the expected title is on screen before
  // asserting on it.
  Future<void> expectMemoriesTitle(WidgetTester tester, String text) async {
    final storyScroll = find
        .descendant(
          of: find.byType(StoryPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: storyScroll,
    );
    expect(find.text(text), findsOneWidget);
  }

  // The quotes sit in the Words tab's sliver list, so scroll the Words
  // page until the expected quote is on screen first.
  Future<void> expectWordsQuote(WidgetTester tester, String text) async {
    final wordsScroll = find
        .descendant(
          of: find.byType(WordsPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.textContaining(text),
      200,
      scrollable: wordsScroll,
    );
    expect(find.textContaining(text), findsOneWidget);
  }

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    expect(find.byType(LolaApp), findsOneWidget);
    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('Home shell tabs render without layout/scroll errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());

    // Splash -> Home (splash has an infinite petal animation, so use
    // fixed-duration pumps instead of pumpAndSettle).
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomePage), findsOneWidget);

    // Pump through frames for every tab to surface any layout exception.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: 'No exception expected on tab $i',
      );
    }
  });

  testWidgets('Content is Tagalog by default and translates to English', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());

    // Splash -> Home (Tagalog by default).
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomePage), findsOneWidget);

    // The Story tab shows the Tagalog quote by default.
    expect(storyQuote('Marunong and Diyos'), findsOneWidget);

    // Switch to English via the language toggle. Fixed-duration pumps only
    // (the gallery spinners animate forever, so pumpAndSettle would time out).
    await tester.tap(find.text('TL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The same quote is now in English.
    expect(
      storyQuote('The kitchen is where love becomes flavor'),
      findsOneWidget,
    );

    // The memories on the home page follow too — English items.
    await expectMemoriesTitle(tester, 'Her Home');
    expect(tester.takeException(), isNull);

    // The Family tab shows the family name and search bar. Pumps after nav
    // taps must outlast the hero's 340ms tab-switch timer, or the test
    // binding fails with "A Timer is still pending" at teardown.
    await tester.tap(navLabel('Family'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(familyTitle('The Lumbao Family'), findsOneWidget);
    expect(find.text('Search for a family member'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All tabs render Tagalog content by default', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Home/Story tab
    expect(storyQuote('Marunong and Diyos'), findsOneWidget);

    // Memories section on the home tab
    await expectMemoriesTitle(tester, 'Ang Kanyang Tahanan');

    // Family tab: family name + search bar in Tagalog. Pumps after every
    // nav tap must outlast the hero's 340ms tab-switch timer, or the test
    // binding fails with "A Timer is still pending" at teardown.
    await tester.tap(navLabel('Pamilya'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(familyTitle('Ang Pamilyang Lumbao'), findsOneWidget);
    expect(find.text('Maghanap ng kapamilya'), findsOneWidget);

    // Words tab
    await tester.tap(find.text('Mga Salita'));
    await tester.pump(const Duration(milliseconds: 400));
    await expectWordsQuote(tester, 'Salamat sa pag-aaruga, Nay');

    // Pakikiramay tab
    await tester.tap(find.text('Pakikiramay'));
    await tester.pump(const Duration(milliseconds: 400));
    // Label + the single full-width light button.
    expect(find.text('Sindihan ang kandila'), findsNWidgets(2));

    // Gallery tab (spinner while the manifest loads — just ensure no crash)
    await tester.tap(find.text('Galeri'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // Leave the gallery before the test ends: its hero slideshow runs on a
    // periodic Timer that stays pending otherwise, which trips the test
    // binding's no-pending-timers invariant. Heading home cancels it.
    await tester.tap(navLabel('Tahanan'));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Toggling to English translates every tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to English.
    await tester.tap(find.text('TL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Home/Story tab
    expect(
      storyQuote('The kitchen is where love becomes flavor'),
      findsOneWidget,
    );

    // Memories section on the home tab
    await expectMemoriesTitle(tester, 'Her Home');

    // Family tab: family name + search bar in English
    await tester.tap(navLabel('Family'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(familyTitle('The Lumbao Family'), findsOneWidget);
    expect(find.text('Search for a family member'), findsOneWidget);

    // Words tab
    await tester.tap(find.text('Words'));
    await tester.pump(const Duration(milliseconds: 400));
    await expectWordsQuote(tester, 'Thank you for caring for us, Nay');

    // Pakikiramay (Condolences) tab
    await tester.tap(find.text('Condolences'));
    await tester.pump(const Duration(milliseconds: 400));
    // Label + the single full-width light button.
    expect(find.text('Light a candle'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toggling to Bicol translates content', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Switch to Bicol via the language toggle.
    await tester.tap(find.text('TL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Bicol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Story quote in Bicol.
    expect(storyQuote('An kusina iyo kun saen'), findsOneWidget);

    // Memories section on the home tab in Bicol.
    await expectMemoriesTitle(tester, 'An Saiyang Harong');

    // Family tab: family name + search bar in Bicol.
    await tester.tap(navLabel('Pamilya'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(familyTitle('An Pamilyang Lumbao'), findsOneWidget);
    expect(find.text('Maghanap nin kapamilya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings gear opens the settings page and back', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomePage), findsOneWidget);

    // Gear sits in the top bar next to the language toggle.
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    // Two pumps: the first inserts the new route's overlay entries, the
    // second completes its transition (single-pump pushes never settle
    // here because overlay insertion itself schedules the next frame).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Mga Setting'), findsOneWidget);
    // Searchable menu: three rows, functional search pill.
    expect(find.text('Maghanap ng setting...'), findsOneWidget);
    expect(find.text('Tungkol sa Developer'), findsOneWidget);
    expect(find.text('Tungkol sa Amin'), findsOneWidget);
    expect(find.text('Makipag-ugnayan'), findsOneWidget);

    // Search filters live: 'ugnay' matches only the contact row.
    await tester.enterText(find.byType(TextField), 'ugnay');
    await tester.pump();
    expect(find.text('Tungkol sa Amin'), findsNothing);
    expect(find.text('Makipag-ugnayan'), findsOneWidget);

    // Tapping a row pushes its detail page.
    await tester.tap(find.text('Makipag-ugnayan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Contact form: intro, three fields, disabled send, privacy note.
    expect(find.text('Iyong pangalan'), findsOneWidget);
    expect(find.text('Ilagay ang iyong pangalan'), findsOneWidget);
    expect(find.text('Mensahe'), findsOneWidget);
    expect(find.text('Mag-send ng mensahe'), findsOneWidget);
    expect(
      find.text('Ang iyong mensahe ay iingatan nang may pagmamahal.'),
      findsOneWidget,
    );

    // Typing a message enables sending without throwing.
    await tester.enterText(
      find.widgetWithText(TextField, 'Isulat ang iyong mensahe para sa pamilya…'),
      'Salamat, Nay',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Back returns to the menu, then home.
    Navigator.of(tester.element(find.text('Mag-send ng mensahe'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(SettingsPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
