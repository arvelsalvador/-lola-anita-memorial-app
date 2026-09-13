import 'package:nita/models/family_model.dart';

class FamilyController {
  static const FamilyModel data = FamilyModel(
    rootMember: FamilyMember(
      name: 'Anita Daiz Lumbao',
      roleKey: 'family_root_subtitle', // "Sentro ng aming pamilya"
      yearsLabel: '1938–2022',
      photoCount: 12,
      photoPath: 'assets/images/Family DP/Nanay_dp.jpg',
    ),
    totalMembers: 32,
    generations: 4,
    groups: [
      FamilyGroup(
        labelKey: 'family_group_siblings',
        subtitleKey: 'family_group_siblings_sub', // "3 kapatid"
        count: 3,
        members: [
          FamilyMember(
            name: 'Roberto Daiz',
            roleKey: 'family_role_brother',
            photoPath: 'assets/images/Family DP/obit.jpg',
            bioKey: 'family_member_obit_bio',
            storyKey: 'family_story_obit',
            birthplace: 'Brgy. 7, Mercedes',
            spouseName: 'Josebeth Daiz',
            grandchildrenCount: 5,
            tags: ['PD', 'BD', 'SD'],
            extraCount: 1,
          ),
          FamilyMember(
            name: 'Rodolfo Daiz',
            roleKey: 'family_role_brother',
            photoPath: 'assets/images/Family DP/dolfo.jpg',
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
            photoPath: 'assets/images/Family DP/sonia.jpg',
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
        count: 3,
        members: [
          FamilyMember(
            name: 'Gernan Lumbao',
            roleKey: 'family_role_son',
            photoPath: 'assets/images/Family DP/gernan.jpg',
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
            photoPath: 'assets/images/Family DP/Odin.jpg',
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
            photoPath: 'assets/images/Family DP/lorie.jpg',
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
        count: 8,
        members: [
          FamilyMember(
            name: 'Hanna Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_hanna_bio',
            storyKey: 'family_story_hanna',
            parentName: 'Gernan Lumbao',
            photoPath: 'assets/images/Family DP/hans.png',
          ),
          FamilyMember(
            name: 'Audrey Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_audrey_bio',
            storyKey: 'family_story_audrey',
            parentName: 'Gernan Lumbao',
            photoPath: 'assets/images/Family DP/audrey.png',
          ),
          FamilyMember(
            name: 'Rodel Lumbao Jr.',
            nickname: 'Jongjong',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_jongjong_bio',
            storyKey: 'family_story_jongjong',
            parentName: 'Rodel Lumbao Sr.',
            photoPath: 'assets/images/Family DP/rodel.png',
          ),
          FamilyMember(
            name: 'Rose-ann Lumbao',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_roseann_bio',
            storyKey: 'family_story_roseann',
            parentName: 'Rodel Lumbao Sr.',
            photoPath: 'assets/images/Family DP/Rose-ann.png',
          ),
          FamilyMember(
            name: 'Arvel Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_arvel_bio',
            storyKey: 'family_story_arvel',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/Family DP/arvel.jpg',
          ),
          FamilyMember(
            name: 'Aivan Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_aivan_bio',
            storyKey: 'family_story_aivan',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/Family DP/aivan.jpg',
          ),
          FamilyMember(
            name: 'Honey Salvador',
            roleKey: 'family_role_granddaughter',
            bioKey: 'family_member_honey_bio',
            storyKey: 'family_story_honey',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/Family DP/honey.jpg',
          ),
          FamilyMember(
            name: 'Daniel Salvador',
            roleKey: 'family_role_grandson',
            bioKey: 'family_member_daniel_bio',
            storyKey: 'family_story_daniel',
            parentName: 'Lorie Salvador',
            photoPath: 'assets/images/Family DP/Daniel.png',
          ),
        ],
      ),

      // TODO: Mga Pamangkin (nieces & nephews) group — redesigning, removed for now
      // TODO: Other Relatives group — redesigning, removed for now
    ],
  );

  static const childrenCount = 6;
  static const marriageYears = 54;
  static const generations = 3;
  static const siblingsCount = 7;
}
