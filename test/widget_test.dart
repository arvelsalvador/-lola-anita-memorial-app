import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nita/app.dart';
import 'package:nita/views/home_page.dart';
import 'package:nita/views/splash_page.dart';

void main() {
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
    await tester.tap(find.text('Touch to enter'));
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
}