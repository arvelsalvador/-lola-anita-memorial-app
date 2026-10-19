import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/app.dart';
import 'package:nita/views/settings/settings_page.dart';
import 'package:nita/views/splash/splash_page.dart';

/// The admin page moved out of `views/settings/` into its own
/// `views/admin/` library. The hidden entry (four footer taps) must keep
/// working, since it is the only way into moderation.
void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'guide_seen_v4': true});
  });

  Future<void> passGate(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(SplashPage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).at(0), 'Test Visitor');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Purok 3, Mercedes, Camarines Norte',
    );
    await tester.pump();
    await tester.tap(find.text('Pumasok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Four footer taps open the admin PIN dialog', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LolaApp());
    await passGate(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsPage), findsOneWidget);

    final footer = find.textContaining('Nanay Anita ·');
    expect(footer, findsOneWidget);
    await tester.ensureVisible(footer);
    await tester.pump();

    for (var i = 0; i < 4; i++) {
      await tester.tap(footer);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Admin copy is English-only by design (see admin_page.dart).
    expect(find.text('Family access'), findsOneWidget);
    expect(find.text('PIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
