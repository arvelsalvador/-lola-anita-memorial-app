import 'package:nita/core/constants/memorial.dart';
import 'package:nita/models/family_model.dart';

class FamilyController {
  static const FamilyModel data = FamilyModel(
    rootMember: FamilyMember(
      name: 'Anita Daiz Lumbao',
      roleKey: 'family_root_subtitle', // "Sentro ng aming pamilya"
      yearsLabel: Memorial.yearsLabel,
      photoCount: 12,
      photoPath: 'assets/images/family_dp/Nanay_dp.png',
    ),
    totalMembers: Memorial.totalMembers,
    generations: Memorial.generations,
    groups: [
      FamilyGroup(
        labelKey: 'family_group_siblings',
        subtitleKey: 'family_group_siblings_sub', // "3 kapatid"
        members: [
          FamilyMember(
            name: 'Roberto Daiz',
            roleKey: 'family_role_brother',
            photoPath: 'assets/images/family_dp/obit.jpg',
            bioKey: 'family_member_obit_bio',
            storyKey: 'family_story_obit',
            birthplace: 'Brgy. 7, Mercedes',
            spouseName: 'Josebeth Daiz',
            grandchildrenCount: 5,
            tags: ['PD', 'BD', 'SD'],
            extraCount: 1,
          ),
          // TODO(i18n): occupation/birthplace are English-only display
          // strings pending translation keys — values kept verbatim so no
          // family facts are invented.
          FamilyMember(
            name: 'Rodolfo Daiz',
            roleKey: 'family_role_brother',
            photoPath: 'assets/images/family_dp/dolfo.jpg',
            bioKey: 'family_member_rodolfo_bio',
            storyKey: 'family_story_rodolfo',
            birthplace: 'Brgy. 7, Mercedes',
            occupation: 'Fisherman',
            spouseName: 'Lolita Daiz',
            childrenCount: 3,
            grandchildrenCount: 5,
          ),
          FamilyMember(
            name: 'Sonia Daiz',
            roleKey: 'family_role_sister',
            photoPath: 'assets/images/family_dp/sonia.jpg',
            bioKey: 'family_member_sonia_bio',
            storyKey: 'family_story_sonia',
            birthplace: 'Brgy. 7, Mercedes',
            occupation: 'Brgy Official',
            childrenCount: 2,
            grandchildrenCount: 3,
          ),
        ],
      ),
      FamilyGroup(
        labelKey: 'family_group_children',
        subtitleKey: 'family_group_children_sub', // "3 anak"
        members: [
          FamilyMember(
            name: 'Gernan Lumbao',
            roleKey: 'family_role_son',
            photoPath: 'assets/images/family_dp/gernan.jpg',
            bioKey: 'family_member_gernan_bio',
            storyKey: 'family_story_gernan',
            birthplace: 'Brgy. 7, Mercedes, Camarines Norte',
            occupation: 'Painter / Laborer',
            childrenCount: 2,
            tags: ['ML', 'GL'],
            spouseName: 'Milagros Lumbao',
          ),
          FamilyMember(
            name: 'Rodel Lumbao Sr.',
            roleKey: 'family_role_second_son',
            photoPath: 'assets/images/family_dp/Odin.jpg',
            bioKey: 'family_member_odin_bio',
            storyKey: 'family_story_odin',
            birthplace: 'Brgy. 7, Mercedes, Camarines Norte',
            occupation: 'Farmer',
            childrenCount: 2,
            grandchildrenCount: 1,
            tags: ['RL'],
            spouseName: 'Mersilita Lumbao',
          ),
          FamilyMember(
            name: 'Lorie Salvador',
            roleKey: 'family_role_bunso',
            photoPath: 'assets/images/family_dp/lorie.jpg',
            bioKey: 'family_member_lorie_bio',
            storyKey: 'family_story_lorie',
            birthplace: 'Brgy. 7, Mercedes, Camarines Norte',
            occupation: 'PAGASA Weather Observer',
            childrenCount: 4,
            tags: ['SJ'],
            spouseName: 'Elben Salvador',
          ),
        ],
      ),
      FamilyGroup(
        labelKey: 'family_group_grandchildren',
        subtitleKey: 'family_group_grandchildren_sub',
        members: [
          FamilyMember(
            name: 'Hanna Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_hanna_bio',
            storyKey: 'family_story_hanna',
            parentName: 'Gernan Lumbao',
            photoPath: 'assets/images/family_dp/hans.png',
          ),
          FamilyMember(
            name: 'Audrey Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_audrey_bio',
            storyKey: 'family_story_audrey',
            parentName: 'Gernan Lumbao',
            photoPath: 'assets/images/family_dp/audrey.png',
          ),
          FamilyMember(
            name: 'Rodel Lumbao Jr.',
            nickname: 'Jongjong',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_jongjong_bio',
            storyKey: 'family_story_jongjong',
            parentName: 'Rodel Lumbao Sr.',
            photoPath: 'assets/images/family_dp/rodel.png',
          ),
          FamilyMember(
            name: 'Rose-ann Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_roseann_bio',
            storyKey: 'family_story_roseann',
            parentName: 'Rodel Lumbao Sr.',
            photoPath: 'assets/images/family_dp/Rose-ann.png',
          ),
          FamilyMember(
            name: 'Arvel Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_arvel_bio',
            storyKey: 'family_story_arvel',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/family_dp/arvel.jpg',
          ),
          FamilyMember(
            name: 'Aivan Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_aivan_bio',
            storyKey: 'family_story_aivan',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/family_dp/aivan.jpg',
          ),
          FamilyMember(
            name: 'Honey Salvador',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_honey_bio',
            storyKey: 'family_story_honey',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/family_dp/honey.jpg',
          ),
          FamilyMember(
            name: 'Daniel Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_daniel_bio',
            storyKey: 'family_story_daniel',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/family_dp/Daniel.png',
          ),
        ],
      ),

      // TODO: Mga Pamangkin (nieces & nephews) group — redesigning, removed for now
      // TODO: Other Relatives group — redesigning, removed for now
    ],
  );

  static const childrenCount = Memorial.childrenCount;
  // UNRESOLVED FACT — needs the family's confirmation. Do not guess a
  // number. marriage_desc (timeline) says 54 years of marriage, and the
  // en/tl bios ("Fifty-four years" / "Limampu't apat na taon" ng
  // pagsasama) repeat the 54 figure. Ask the family whether this span is
  // true before changing this value or that story.
  static const marriageYears = 54;
  static const generations = Memorial.generations;
  static const siblingsCount = Memorial.siblingsCount;
}
