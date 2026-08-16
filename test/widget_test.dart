import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nita/app.dart';
import 'package:nita/views/home_page.dart';
import 'package:nita/views/splash_page.dart';
import 'package:nita/views/story_page.dart';
import 'package:nita/widgets/bottom_nav.dart';

void main() {
  // The header's "Memories" CTA shares its label with the bottom nav, so
  // tab taps must be scoped to the nav bar to stay unambiguous.
  Finder navLabel(String text) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text(text),
      );

  // The hero header repeats the Story tab's quote, so quote assertions
  // must be scoped to the StoryPage body to stay unambiguous.
  Finder storyQuote(String text) => find.descendant(
        of: find.byType(StoryPage),
        matching: find.textContaining(text),
      );

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    expect(find.byType(LolaApp), findsOneWidget);
    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('Home shell tabs render without layout/scroll errors',
      (WidgetTester tester) async {
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
      expect(tester.takeException(), isNull,
          reason: 'No exception expected on tab $i');
    }
  });

  testWidgets('Content is Tagalog by default and translates to English',
      (WidgetTester tester) async {
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
    expect(storyQuote('Ang kusina ay kung saan'), findsOneWidget);

    // Switch to English via the language toggle. Fixed-duration pumps only
    // (the gallery spinners animate forever, so pumpAndSettle would time out).
    await tester.tap(find.text('TL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The same quote is now in English.
    expect(storyQuote('The kitchen is where love becomes flavor'),
        findsOneWidget);

    // Page content follows too — Memories tab shows English items.
    await tester.tap(navLabel('Memories'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sunday Kare-Kare'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All tabs render Tagalog content by default',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await tester.tap(find.text('Pindutin upang pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Home/Story tab
    expect(storyQuote('Ang kusina ay kung saan'), findsOneWidget);

    // Memories tab
    await tester.tap(navLabel('Mga Alaala'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lingguhang Kare-Kare'), findsOneWidget);

    // Tribute tab
    await tester.tap(find.text('Pagkilala'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hanggang sa muli tayong magkita'), findsOneWidget);

    // Favorites tab
    await tester.tap(find.text('Mga Paborito'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Paghahalaman'), findsOneWidget);

    // Gallery tab (spinner while the manifest loads — just ensure no crash)
    await tester.tap(find.text('Galeri'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toggling to English translates every tab',
      (WidgetTester tester) async {
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
    expect(storyQuote('The kitchen is where love becomes flavor'),
        findsOneWidget);

    // Memories tab
    await tester.tap(navLabel('Memories'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sunday Kare-Kare'), findsOneWidget);

    // Tribute tab
    await tester.tap(find.text('Tribute'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Until we meet again'), findsOneWidget);

    // Favorites tab
    await tester.tap(find.text('Favorites'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Gardening'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toggling to Bicol translates content',
      (WidgetTester tester) async {
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

    // Memories tab in Bicol.
    await tester.tap(navLabel('Mga Alaala'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kare-Kare sa Domingo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}