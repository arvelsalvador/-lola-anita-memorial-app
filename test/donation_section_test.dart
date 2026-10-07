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

    testWidgets('shows placeholder while QR asset is absent', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      // No real QR file is bundled yet — the graceful fallback shows.
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.textContaining('QR'), findsWidgets);
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
      final copyFinder = find.text('Copy');
      expect(copyFinder, findsOneWidget);
      await tester.scrollUntilVisible(copyFinder, 200);
      await tester.pumpAndSettle();
      await tester.tap(copyFinder);
      await tester.pumpAndSettle();
      expect(stored, DonationDetails.gcashNumber);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('GCash number copied'), findsOneWidget);
    });

    testWidgets('open GCash button is present', (tester) async {
      await tester.pumpWidget(_harness(language: AppLanguage.english));
      await tester.pumpAndSettle();
      expect(find.text('Open GCash'), findsOneWidget);
    });
  });
}
