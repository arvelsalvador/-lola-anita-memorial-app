import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/widgets/balanced_justify_text.dart';

void main() {
  testWidgets('story card copy is justified', (tester) async {
    // Phone width: the narrow memory-card column is where justification
    // used to open up oversized word gaps.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const AboutCard(text: 'About body'),
                  MemoryCard(
                    memory: HomeController.memoriesData.memories.first,
                    index: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The wide "about" card justifies directly.
    final about = tester.widget<Text>(find.text('About body'));
    expect(about.textAlign, TextAlign.justify);

    // The narrow memory card re-breaks its paragraph before justifying, so
    // the body is rendered by BalancedJustifyText.
    final balanced = tester.widget<BalancedJustifyText>(
      find.byType(BalancedJustifyText),
    );
    expect(balanced.textAlign, TextAlign.justify);

    final body = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(BalancedJustifyText),
            matching: find.byType(Text),
          ),
        )
        .single;
    expect(body.textAlign, TextAlign.justify);
    // Balanced line breaks are inserted as hard newlines.
    expect(body.data, contains('\n'));

    // The title follows the approved Memories_design mock: a large carved
    // serif heading, centred over the body, with the short gold rule under
    // it. It is not line-capped — the card grows instead of truncating.
    final title = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(MemoryCard),
            matching: find.byType(Text),
          ),
        )
        .firstWhere((text) => text.style?.fontFamily == 'PlayfairDisplay');
    expect(title.textAlign, TextAlign.center);
    expect(title.maxLines, isNull);
    expect(title.style, AppTextStyles.memoryCardTitle);
    expect(
      AppTextStyles.memoryCardTitle.fontSize,
      greaterThan(AppTextStyles.homeContent.fontSize!),
    );
    expect(find.byKey(const ValueKey('memory-title-rule')), findsOneWidget);
  });

  test('family and settings story copy stays justified', () {
    for (final path in const [
      'lib/views/family/family_member_viewer.dart',
      'lib/views/settings/settings_developer.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('TextAlign.justify'),
        reason: '$path must keep story copy justified.',
      );
    }
  });
}
