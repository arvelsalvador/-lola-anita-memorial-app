import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/home_shell.dart';
import 'package:nita/widgets/hero_header.dart';

void _noop(int _) {}

/// The hero's collapse container height — 0 means the hero is hidden, the
/// full expanded height means it is shown. Read after the fixed pumps so the
/// collapse animation has finished.
double _heroHeight(WidgetTester tester) => tester
    .getSize(
      find.byKey(const ValueKey('hero-collapse'), skipOffstage: false),
    )
    .height;

void main() {
  testWidgets('hero hides on scroll and only returns at the top',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(
          home: HomeShell(selectedTab: 0, onTabChanged: _noop),
        ),
      ),
    );
    // Fixed pumps: the gallery tab shows an indefinite spinner, so
    // pumpAndSettle would never settle.
    await tester.pump(const Duration(milliseconds: 400));

    // At rest the hero is fully expanded, below the fixed top bar.
    final brandBefore = tester.getTopLeft(find.text('nanay anita')).dy;
    final heroTopBefore = tester.getTopLeft(
      find.byType(LolaHeroHeader, skipOffstage: false),
    ).dy;
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

    // Only when the scroll reaches the very top does the hero come back.
    await tester.dragFrom(const Offset(100, 520), const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_heroHeight(tester), greaterThan(0));
    expect(tester.getTopLeft(find.text('nanay anita')).dy, brandBefore);
  });
}
