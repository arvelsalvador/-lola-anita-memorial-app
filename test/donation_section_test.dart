import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/donation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/donation_section.dart';

Widget _harness({AppLanguage? language}) {
  final provider = LanguageProvider();
  if (language != null) provider.setLanguage(language);
  return ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DonationSection())),
    ),
  );
}

void main() {
  group('DonationSection (Abuloy)', () {
    testWidgets('shows Tagalog title by default', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.text('Abuloy para sa Pamilya'), findsOneWidget);
    });

    testWidgets('shows English title when switched', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      expect(find.text('Abuloy for the Family'), findsOneWidget);
    });

    testWidgets('shows the selected account QR image', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      // Real QR files are bundled, so the selected account's Image shows.
      // (In old runs with no QR file, the graceful placeholder showed.)
      final hasQr = find
          .byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName ==
                    DonationDetails.accounts.first.qrAssetPath,
          )
          .evaluate()
          .isNotEmpty;
      final hasPlaceholder = find
          .byIcon(Icons.qr_code_2_rounded)
          .evaluate()
          .isNotEmpty;
      expect(hasQr || hasPlaceholder, isTrue);
    });

    testWidgets('shows both masked family GCash accounts', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      expect(find.text('MA*C AR**L S.', skipOffstage: false), findsWidgets);
      expect(find.text('LO**E S.', skipOffstage: false), findsWidgets);
      expect(find.text('0909063 ****'), findsOneWidget);
      expect(find.text('0946835 ****'), findsOneWidget);
      // Full numbers must never be shown on screen.
      expect(find.text('09090634076'), findsNothing);
      expect(find.text('09468357721'), findsNothing);
    });

    testWidgets('tapping a name switches the shown QR', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();

      bool hasQr(String path) => find
          .byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == path,
          )
          .evaluate()
          .isNotEmpty;

      // Default selection is the first account.
      expect(hasQr(DonationDetails.accounts.first.qrAssetPath), isTrue);

      // Tap the second account row to select its QR.
      await tester.tap(find.text('0946835 ****'));
      await tester.pumpAndSettle();
      expect(hasQr(DonationDetails.accounts[1].qrAssetPath), isTrue);
    });

    testWidgets('copy button confirms with a SnackBar', (tester) async {
      // flutter_test leaves SystemChannels.platform unmocked, so a real
      // Clipboard.setData await would hang forever. Mock it in-memory.
      String? stored;
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            stored = (call.arguments as Map)['text'] as String?;
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
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      final copyFinder = find.byTooltip('Copy');
      expect(copyFinder, findsNWidgets(2));
      final firstCopy = copyFinder.first;
      await tester.scrollUntilVisible(firstCopy, 200);
      await tester.pumpAndSettle();
      await tester.tap(firstCopy);
      await tester.pumpAndSettle();
      expect(stored, '09090634076');
      expect(stored, DonationDetails.accounts.first.copyNumber);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Number copied — paste it in GCash, then enter amount'),
        findsOneWidget,
      );
    });

    testWidgets('second account copies its own number', (tester) async {
      String? stored;
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            stored = (call.arguments as Map)['text'] as String?;
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
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      final secondCopy = find.byTooltip('Copy').at(1);
      await tester.scrollUntilVisible(secondCopy, 200);
      await tester.pumpAndSettle();
      await tester.tap(secondCopy);
      await tester.pumpAndSettle();
      expect(stored, '09468357721');
      expect(stored, DonationDetails.accounts[1].copyNumber);
    });

    testWidgets('open GCash button is present', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      expect(find.text('Open GCash'), findsOneWidget);
    });
  });
}
