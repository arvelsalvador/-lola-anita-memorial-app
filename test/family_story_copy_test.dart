import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/family_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/localization/translations_tl.dart';
import 'package:nita/views/family/family_page.dart';

/// Copy + layout guard for the Tagalog member stories shown in the Pamilya
/// detail sheet. The sheet is the only place these strings render; the cards
/// themselves carry only the photo and name.
void main() {
  test('requested Tagalog story edits are in the translation map', () {
    String story(String key) => translationsTl[key]!;

    expect(
      story('family_story_rodolfo'),
      contains(
        'Tumutulong siya sa mga kapamilya, lalo na kay Lorie, anak ni Anita',
      ),
    );
    expect(
      story('family_story_rodolfo'),
      isNot(contains('mga anak ng kapatid')),
    );

    expect(story('family_story_sonia'), contains('barangay official'));
    expect(story('family_story_sonia'), isNot(contains('barangay tanod')));
    expect(
      translationsTl['family_member_sonia_bio'],
      contains('barangay official'),
    );
    expect(
      translationsTl['family_member_sonia_bio'],
      isNot(contains('barangay tanod')),
    );

    expect(
      story('family_story_gernan'),
      contains('Si Gernan ay ang buhay na panganay na anak ni Anita'),
    );

    expect(
      story('family_story_lorie'),
      contains('Si Lorie ay ang nag-alaga at nagbantay sa kanyang ina.'),
    );
    expect(story('family_story_lorie'), contains('apat na anak'));
    expect(story('family_story_lorie'), isNot(contains('talinong')));

    expect(
      story('family_story_hanna'),
      contains('Masayahin at puno siya ng enerhiya.'),
    );
    expect(
      story('family_story_hanna'),
      isNot(contains('parang nagliwanag ang bawat silid')),
    );

    expect(
      story('family_story_audrey'),
      contains('ipinapakita niya ang tunay na sarili.'),
    );
    expect(
      story('family_story_audrey'),
      isNot(contains('pinakamagandang suot')),
    );

    expect(story('family_story_jongjong'), contains('Makulit siya at'));
    expect(
      story('family_story_jongjong'),
      isNot(contains('minana ang init ng loob')),
    );

    expect(story('family_story_arvel'), contains('Simpleng anak ni Lorie'));
    expect(
      story('family_story_arvel'),
      contains('naglilingkod siya at patuloy na minamahal ang kanyang pamilya'),
    );

    expect(
      story('family_story_roseann'),
      contains(
        'Masigla si Rose Ann, at dala niya ang saya sa bawat pagtitipon.',
      ),
    );
    expect(story('family_story_roseann'), isNot(contains('madaldal')));
    expect(story('family_story_roseann'), isNot(contains('init')));
    expect(story('family_story_roseann'), isNot(contains('tahimik')));
    expect(story('family_story_roseann'), isNot(contains('Maamo')));
    expect(story('family_story_roseann'), isNot(contains('banayad')));

    expect(
      story('family_story_aivan'),
      'Magaling makipag-usap at makisama sa kahit sino. Madali siyang '
      'makipagkaibigan, marunong makinig, at laging may paraan para '
      'gumaan ang pakiramdam ng mga kasama niya.',
    );
    expect(
      story('family_story_daniel'),
      'Teknikal si Daniel, magaling mag-ayos ng motor at electronics. '
      "Kapag may sirang makina o gamit sa bahay, siya ang unang "
      "nilalapitan ng pamilya, at bihira siyang sumuko hangga't hindi "
      'ito gumagana muli.',
    );
    expect(
      story('family_story_honey'),
      'Palaban si Honey, sa sports man o sa pag-aaral.',
    );
  });

  const editedMembers = [
    'Rodolfo Daiz',
    'Sonia Daiz',
    'Gernan Lumbao',
    'Audrey Lumbao',
    'Lorie Salvador',
    'Hanna Lumbao',
    'Rodel Lumbao Jr.',
    'Rose-ann Lumbao',
    'Arvel Salvador',
    'Aivan Salvador',
    'Honey Salvador',
    'Daniel Salvador',
  ];
  final allMembers = FamilyController.data.groups
      .expand((group) => group.members)
      .toList();

  for (final name in editedMembers) {
    testWidgets('$name story is not clipped at 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final lang = LanguageProvider();
      final member = allMembers.firstWhere((m) => m.name == name);
      final story = lang.t(member.storyKey!);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: lang,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showMemberDetailSheet(context, member),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final storyFinder = find.text(story);
      expect(storyFinder, findsOneWidget);
      final storyWidget = tester.widget<Text>(storyFinder);
      expect(storyWidget.maxLines, isNull);
      expect(storyWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });
  }
}
