import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/donation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/abuloy_touch.dart';

Widget _harness({AppLanguage? language}) {
  final provider = LanguageProvider();
  if (language != null) provider.setLanguage(language);
  return ChangeNotifierProvider.value(
    value: provider,
    // SizedBox.expand gives the Stack bounded constraints, mirroring the
    // HomeShell stack the touch lives in on real screens.
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(child: Stack(children: [AbuloyTouch()])),
      ),
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
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Abuloy')), findsOneWidget);
    });

    testWidgets('tap opens the dialog with QR placeholder', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pumpAndSettle();
      expect(find.text('Abuloy for the Family'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Open GCash'), findsOneWidget);
    });

    testWidgets('close button dismisses the dialog', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pumpAndSettle();
      expect(find.text('Abuloy for the Family'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Abuloy for the Family'), findsNothing);
    });

    testWidgets('copy inside the dialog confirms', (tester) async {
      String? stored;
      _mockClipboard(() => stored, (v) => stored = v);
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AbuloyTouch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(stored, DonationDetails.gcashNumber);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('docks bottom-right by default', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final el = tester.element(find.byType(AbuloyTouch));
      final size = MediaQuery.sizeOf(el);
      final padding = MediaQuery.paddingOf(el);
      final pos = touchPosition(tester);
      expect(pos.left, size.width - 20 - AbuloyTouch.size);
      expect(pos.top, size.height - padding.bottom - 104 - AbuloyTouch.size);
    });

    testWidgets('drag moves it without opening the dialog', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      final before = touchPosition(tester);
      await tester.drag(find.byType(AbuloyTouch), const Offset(-120, -80));
      await tester.pumpAndSettle();
      final after = touchPosition(tester);
      expect(after.left, lessThan(before.left!));
      expect(after.top, lessThan(before.top!));
      // A drag must not count as a tap.
      expect(find.text('Abuloy for the Family'), findsNothing);
    });

    testWidgets('drag clamps inside the screen', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(AbuloyTouch), const Offset(5000, 5000));
      await tester.pumpAndSettle();
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
  });
}
