import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';

/// Short landscape viewports (640x360 and similar) used to overflow the
/// Home body: the memorial hero kept its 460px floor inside a non-scrolling
/// Column, leaving the content panel no room. The hero is now capped at the
/// viewport height minus [_heroReservedExtent], so both fit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // VisibilityDetector defers callbacks on a periodic timer, which
    // otherwise stays pending at teardown and fails the test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('home fits a 640x360 landscape viewport without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'visitor_name': 'Maria Santos',
      'visitor_address': 'Daet, Camarines Norte',
      // Returning device: no first-run guide over the home shell.
      'guide_seen_v4': true,
    });
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(),
        ),
      ),
    );
    // Fixed pumps, not pumpAndSettle: the hero and gallery keep animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomeShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
