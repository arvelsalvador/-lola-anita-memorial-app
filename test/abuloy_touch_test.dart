import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/donation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/abuloy_touch.dart';

Widget _harness({AppLanguage? language}) {
  final provider = LanguageProvider();
  if (language != null) provider.setLanguage(language);
  return ChangeNotifierProvider.value(
    value: provider,
    // SizedBox.expand gives the scope's Stack bounded constraints, mirroring
    // the HomeShell stack the touch lives in on real screens. The scope
    // measures them parent-side and hands the size to the touch.
    child: const MaterialApp(
      home: Scaffold(body: AbuloyTouchScope(child: SizedBox.expand())),
    ),
  );
}

/// The self-positioning [Positioned] rendered by [AbuloyTouch], located
/// via the touch icon it wraps.
Positioned touchPosition(WidgetTester tester) => tester.widget<Positioned>(
  find.ancestor(
    of: find.byIcon(Icons.volunteer_activism_outlined),
    matching: find.byType(Positioned),
  ),
);

/// In-memory clipboard mock: flutter_test leaves SystemChannels.platform
/// unmocked, so a real Clipboard.setData await would hang forever.
void _mockClipboard(String? Function() read, void Function(String?) write) {
  final binding = TestDefaultBinaryMessengerBinding.instance;
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        write((call.arguments as Map)['text'] as String?);
      } else if (call.method == 'Clipboard.getData') {
        final text = read();
        if (text == null) return null;
        return <String, dynamic>{'text': text};
      }
      return null;
    },
  );
  addTearDown(
    () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

void main() {
  group('AbuloyTouch (floating assistive touch)', () {
    testWidgets('renders with the donate label', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Abuloy')), findsOneWidget);
    });

    testWidgets('tap opens the dialog with selectable QR', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pump(const Duration(milliseconds: 100));
      // Extra frame: the QR Image.asset resolves its bundle entry.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Abuloy for the Family'), findsOneWidget);
      // Real QR files are bundled: either the Image or the graceful
      // placeholder (if the bundle misses it) is acceptable.
      final hasQrImage = find
          .byWidgetPredicate((w) => w is Image && w.image is AssetImage)
          .evaluate()
          .isNotEmpty;
      final hasPlaceholder = find
          .byIcon(Icons.qr_code_2_rounded)
          .evaluate()
          .isNotEmpty;
      expect(hasQrImage || hasPlaceholder, isTrue);
      expect(find.text('MA*C AR**L S.', skipOffstage: false), findsWidgets);
      expect(find.text('LO**E S.', skipOffstage: false), findsWidgets);
      expect(find.byTooltip('Copy'), findsNWidgets(2));
      expect(find.byIcon(Icons.copy_outlined), findsNWidgets(2));
      expect(find.text('Open GCash'), findsOneWidget);
    });

    testWidgets('shows a white glyph on the gold coin', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 100));
      final glyph = tester.widget<Icon>(
        find.byIcon(Icons.volunteer_activism_outlined),
      );
      expect(glyph.color, Colors.white);
      final coin = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.volunteer_activism_outlined),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((coin.decoration! as BoxDecoration).color, AppColors.gold);
    });

    testWidgets('close button dismisses the dialog', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Abuloy for the Family'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Abuloy for the Family'), findsNothing);
    });

    testWidgets('copy inside the dialog confirms', (tester) async {
      String? stored;
      _mockClipboard(() => stored, (v) => stored = v);
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Copy').first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(stored, DonationDetails.accounts.first.copyNumber);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('docks top-right by default', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 100));
      final el = tester.element(find.byType(AbuloyTouch));
      final size = MediaQuery.sizeOf(el);
      final pos = touchPosition(tester);
      // closeTo: the dock point round-trips through fractions (tiny FP dust).
      expect(pos.left, closeTo(size.width - 20 - AbuloyTouch.size, 0.001));
      expect(pos.top, closeTo(AbuloyTouch.dockTopFor(size), 0.001));
    });

    testWidgets('drag moves it without opening the dialog', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pump(const Duration(milliseconds: 100));
      final before = touchPosition(tester);
      await tester.drag(find.byType(AbuloyTouch), const Offset(-120, -80));
      await tester.pump(const Duration(milliseconds: 100));
      final after = touchPosition(tester);
      expect(after.left, lessThan(before.left!));
      expect(after.top, lessThan(before.top!));
      // A drag must not count as a tap.
      expect(find.text('Abuloy for the Family'), findsNothing);
    });

    testWidgets('drag clamps inside the screen', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.drag(find.byType(AbuloyTouch), const Offset(5000, 5000));
      await tester.pump(const Duration(milliseconds: 100));
      final el = tester.element(find.byType(AbuloyTouch));
      final size = MediaQuery.sizeOf(el);
      final padding = MediaQuery.paddingOf(el);
      final pos = touchPosition(tester);
      expect(pos.left, size.width - AbuloyTouch.size - AbuloyTouch.margin);
      expect(
        pos.top,
        size.height - padding.bottom - AbuloyTouch.size - AbuloyTouch.margin,
      );
    });

    testWidgets('tracks 1:1 when events arrive between frames', (tester) async {
      // Regression test for the laggy drag: several pointer events can land
      // before the next rebuild, and every delta must count â€” basing each
      // update on the last *built* position silently drops movement.
      // (The first move only engages the drag past touch slop, so its exact
      // contribution is excluded: commit it, then assert the next two rapid
      // moves sum exactly.)
      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 100));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AbuloyTouch)),
      );
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      final committed = touchPosition(tester).left!;
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(touchPosition(tester).left, closeTo(committed - 70, 0.001));
    });

    testWidgets('stays put across different stack sizes', (tester) async {
      // The reported bug: middle of Galeri stayed middle on Pamilya/Mga
      // Salita/Pakikiramay (same tall stack) but jumped on Tahanan (short
      // stack under the hero), because the spot was stored in pixels.
      // Fractions keep the relative spot on any stack size.
      final provider = LanguageProvider();
      Widget sizedHarness(double w, double h) => ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(children: [AbuloyTouch(areaSize: Size(w, h))]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(sizedHarness(800, 600));
      await tester.pump(const Duration(milliseconds: 100));
      // Drag near the middle of the tall stack.
      final start = tester.getCenter(find.byType(AbuloyTouch));
      await tester.drag(
        find.byType(AbuloyTouch),
        Offset(374 - start.dx, 274 - start.dy),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final tall = touchPosition(tester);
      // Same state, short stack (like switching to Tahanan): the relative
      // spot must survive. (Widths match, so left is exactly preserved;
      // tops are compared as ratios.)
      await tester.pumpWidget(sizedHarness(800, 300));
      await tester.pump(const Duration(milliseconds: 100));
      final short = touchPosition(tester);
      expect(short.left, tall.left);
      expect(short.top! / 300, moreOrLessEquals(tall.top! / 600));
    });
  });
}
