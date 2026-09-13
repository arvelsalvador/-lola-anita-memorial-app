import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/views/family_page.dart';

/// Tests for the member-DP fullscreen viewer: only the large portrait in
/// the member detail sheet opens it, with pinch-to-zoom and dismiss that
/// returns to the still-open sheet.
void main() {
  Future<void> pumpFamilyPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: LanguageProvider(),
        child: const MaterialApp(home: FamilyPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openSheet(WidgetTester tester, String name) async {
    await tester.scrollUntilVisible(
      find.text(name),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the sheet portrait opens the photo full-screen', (
    tester,
  ) async {
    await pumpFamilyPage(tester);
    await openSheet(tester, 'Hanna Lumbao');

    // Card + sheet instances, plus the tap affordance on the portrait.
    expect(find.text('Hanna Lumbao'), findsNWidgets(2));
    expect(find.byTooltip('View full photo'), findsOneWidget);

    await tester.tap(find.byTooltip('View full photo'));
    await tester.pumpAndSettle();

    // Viewer: zoomable image, name caption, dedicated close button.
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Hanna Lumbao'), findsNWidgets(3));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Dismissing the viewer returns to the still-open sheet.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Hanna Lumbao'), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('tapping the viewer photo dismisses back to the sheet', (
    tester,
  ) async {
    await pumpFamilyPage(tester);
    await openSheet(tester, 'Hanna Lumbao');

    await tester.tap(find.byTooltip('View full photo'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Tap the photo itself (center of the viewer).
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Hanna Lumbao'), findsNWidgets(2));
  });

  testWidgets('photo-less members have no fullscreen viewer', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: LanguageProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => showMemberPhotoViewer(
                    context,
                    const FamilyMember(
                      name: 'No Photo',
                      roleKey: 'family_role_son',
                    ),
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Early-return: no route pushed, no viewer, no crash.
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('low-res portraits still fill the viewer (Rodolfo Daiz)', (
    tester,
  ) async {
    // Regression: dolfo.jpg is only 200x200px, so an unconstrained image
    // rendered as a small stamp instead of filling the viewer.
    await pumpFamilyPage(tester);
    await openSheet(tester, 'Rodolfo Daiz');

    expect(find.text('Rodolfo Daiz'), findsNWidgets(2));
    await tester.tap(find.byTooltip('View full photo'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);

    // The photo layer must claim the full screen (not intrinsic size):
    // asset images don't decode in widget tests, so assert on the
    // fullscreen bounds box rather than the image pixels.
    final photoBounds = find.descendant(
      of: find.byType(InteractiveViewer),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == double.infinity &&
            w.height == double.infinity,
      ),
    );
    expect(photoBounds, findsOneWidget);
    final size = tester.getSize(photoBounds);
    expect(size.width, closeTo(390, 1.0));
    expect(size.height, greaterThan(700));
  });
}
