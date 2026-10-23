import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/home/home_page.dart';

/// Justified body copy produces the huge, uneven word gaps visible on narrow
/// phone cards. Flutter's default and every card body should be start-aligned
/// (left in LTR), so this scan keeps future cards from reintroducing justify.
void _expectNoJustifiedCopy() {
  final offenders = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.readAsStringSync().contains('TextAlign.justify')) {
      offenders.add(entity.path);
    }
  }
  expect(
    offenders,
    isEmpty,
    reason:
        'Story/card copy must be TextAlign.start, never justify. '
        'Offending files: ${offenders.join(', ')}',
  );
}

void main() {
  test('no card copy is justified', _expectNoJustifiedCopy);

  testWidgets('story cards render their bodies start-aligned', (tester) async {
    final memory = HomeController.memoriesData.memories.first;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                const AboutCard(text: 'About body'),
                MemoryCard(memory: memory, index: 0),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // About card: the only Text is the paragraph.
    final about = tester.widget<Text>(find.text('About body'));
    expect(about.textAlign, TextAlign.start);

    // Memory card: the title stays centred, the body must be start-aligned.
    final cardTexts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(MemoryCard),
            matching: find.byType(Text),
          ),
        )
        .toList();
    expect(cardTexts, isNotEmpty);
    expect(
      cardTexts.where((text) => text.textAlign == TextAlign.justify),
      isEmpty,
    );
    expect(
      cardTexts.where((text) => text.textAlign == TextAlign.start),
      isNotEmpty,
      reason: 'the memory body should be start-aligned, not centred',
    );
  });
}
