import 'package:flutter_test/flutter_test.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/core/constants/memorial.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/display_utils.dart';

void main() {
  group('Memorial dates stay consistent', () {
    test('home grandmother uses Memorial years', () {
      expect(HomeController.grandmother.birthYear, Memorial.birthYear);
      expect(HomeController.grandmother.passingYear, Memorial.passingYear);
    });

    test('lived years match the 85-year story copy', () {
      expect(Memorial.livedYears, 85);
      for (final map in [
        LanguageProvider.en,
        LanguageProvider.tl,
        LanguageProvider.bi,
      ]) {
        expect(map['story_about'], contains('85'));
      }
    });

    test('family root years match Memorial display label', () {
      expect(FamilyController.data.rootMember.yearsLabel, Memorial.yearsLabel);
      expect(
        Memorial.yearsLabel,
        DisplayUtils.yearsLabel(
          Memorial.birthYear,
          Memorial.passingYear,
        ).replaceAll('  ·  ', '–'),
      );
    });

    test('timeline endpoints match Memorial years', () {
      final years = HomeController.data.timeline.map((e) => e.year).toList();
      expect(years.first, '${Memorial.birthYear}');
      expect(years.last, '${Memorial.passingYear}');
    });
  });

  group('Family counts match modeled data', () {
    test('totalMembers equals 1 root + all group members', () {
      final modeled =
          1 +
          FamilyController.data.groups.fold<int>(
            0,
            (sum, g) => sum + g.members.length,
          );
      expect(FamilyController.data.totalMembers, modeled);
      expect(FamilyController.data.totalMembers, Memorial.totalMembers);
    });

    test('each group count matches its members length', () {
      for (final group in FamilyController.data.groups) {
        expect(
          group.count,
          group.members.length,
          reason: 'group ${group.labelKey} count drifted',
        );
      }
    });

    test('sibling/children tallies match groups', () {
      final siblings = FamilyController.data.groups.first.members.length;
      final children = FamilyController.data.groups[1].members.length;
      expect(FamilyController.siblingsCount, siblings);
      expect(FamilyController.childrenCount, children);
    });
  });

  group('Translation keys referenced by data exist in all 3 languages', () {
    Iterable<String> memberKeys() sync* {
      const data = FamilyController.data;
      yield data.rootMember.roleKey;
      for (final group in data.groups) {
        yield group.labelKey;
        yield group.subtitleKey;
        if (group.viewAllLabelKey != null) yield group.viewAllLabelKey!;
        for (final m in group.members) {
          yield m.roleKey;
          if (m.bioKey != null) yield m.bioKey!;
          if (m.storyKey != null) yield m.storyKey!;
          if (m.quoteKey != null) yield m.quoteKey!;
        }
      }
      yield HomeController.data.quoteKey;
      yield HomeController.data.quoteAttributionKey;
      yield HomeController.data.aboutKey;
      yield HomeController.data.favoritesKey;
      for (final e in HomeController.data.timeline) {
        yield e.titleKey;
        yield e.descriptionKey;
      }
      yield 'family_sheet_view_photo';
      yield 'story_favorites';
      yield 'hero_portrait_label';
      yield 'hero_years_label';
    }

    test('no referenced key is missing anywhere', () {
      final missing = <String>[];
      for (final key in memberKeys().toSet()) {
        if (!LanguageProvider.en.containsKey(key) ||
            !LanguageProvider.tl.containsKey(key) ||
            !LanguageProvider.bi.containsKey(key)) {
          missing.add(key);
        }
      }
      expect(missing, isEmpty, reason: 'missing keys: $missing');
    });

    test('family_sheet_view_photo is translated (not raw key)', () {
      final provider = LanguageProvider();
      for (final lang in AppLanguage.values) {
        provider.setLanguage(lang);
        expect(
          provider.t('family_sheet_view_photo'),
          isNot('family_sheet_view_photo'),
        );
      }
    });
  });
}
