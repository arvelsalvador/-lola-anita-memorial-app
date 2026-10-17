import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/splash/splash_page.dart';

/// Deep-link gate guard: on the web a #/home link lands directly on the
/// home route, skipping the splash — so HomePage itself must bounce
/// fresh devices to the gate while remembered devices stay inside.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // VisibilityDetector defers callbacks on a periodic timer, which
    // otherwise stays pending at teardown and fails the test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app({required String initialRoute}) => ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      routes: {
        '/': (_) => const SplashPage(),
        '/splash': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
      },
      initialRoute: initialRoute,
    ),
  );

  testWidgets('fresh device landing on #/home is bounced to the splash gate', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialRoute: '/home'));
    // Fixed pumps, not pumpAndSettle: the splash petals repeat forever
    // and the gallery tab shows an indefinite spinner.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('remembered visitor stays inside on #/home', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('visitor_name', 'Arvel Salvador');
    await prefs.setString('visitor_address', 'Daet, Camarines Norte');

    await tester.pumpWidget(app(initialRoute: '/home'));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
