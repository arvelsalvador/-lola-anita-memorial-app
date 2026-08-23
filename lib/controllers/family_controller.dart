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
        labelKey: 'family_group_children',
        subtitleKey: 'family_group_children_sub', // "3 anak"
        count: 3,
        members: [
          FamilyMember(
            name: 'Gernan Lumbao',
            roleKey: 'family_role_son',
            photoPath: 'assets/images/Family DP/gernan.jpg',
            bioKey: 'family_member_ramon_bio',
            tags: ['ML', 'GL'],
            extraCount: 1,
            spouseName: 'Lola Bashang',
          ),
          FamilyMember(
            name: 'Odin Lumbao',
            roleKey: 'family_role_son',
            photoPath: 'assets/images/Family DP/Odin.jpg',
            bioKey: 'family_member_salvador_jr_bio',
            tags: ['RL'],
            spouseName: 'Lola Ami',
          ),
          FamilyMember(
            name: 'Lorie Salvador',
            roleKey: 'family_role_daughter',
            photoPath: 'assets/images/Family DP/lorie.jpg',
            bioKey: 'family_member_rosario_bio',
            tags: ['SJ'],
            spouseName: 'Elben',
          ),
        ],
      ),
      FamilyGroup(
        labelKey: 'family_group_siblings',
        subtitleKey: 'family_group_siblings_sub', // "3 kapatid"
        count: 3,
        members: [
          FamilyMember(
            name: 'Obit Daiz',
            roleKey: 'family_role_sister',
            photoPath: 'assets/images/Family DP/obit.jpg',
            bioKey: 'family_member_ester_bio',
            tags: ['PD', 'BD', 'SD'],
            extraCount: 1,
          ),
          FamilyMember(
            name: 'Rodolfo Daiz',
            roleKey: 'family_role_brother',
            photoPath: 'assets/images/Family DP/dolfo.jpg',
            bioKey: 'family_member_rodolfo_bio',
          ),
          FamilyMember(
            name: 'Sonia Daiz',
            roleKey: 'family_role_sister',
            photoPath: 'assets/images/Family DP/sonia.jpg',
            bioKey: 'family_member_sonia_bio',
          ),
        ],
      ),
      FamilyGroup(
        labelKey: 'family_group_grandchildren',
        subtitleKey: 'family_group_grandchildren_sub',
        count: 8,
        members: [
          FamilyMember(
            name: 'Hanna Mae',
            roleKey: 'family_role_granddaughter',
            parentName: 'Gernan Lumbao',
          ),
          FamilyMember(
            name: 'Audrey',
            roleKey: 'family_role_granddaughter',
            parentName: 'Gernan Lumbao',
          ),
          FamilyMember(
            name: 'Jongjong',
            roleKey: 'family_role_grandson',
            parentName: 'Odin Lumbao',
          ),
          FamilyMember(
            name: 'Rose-ann',
            roleKey: 'family_role_granddaughter',
            parentName: 'Odin Lumbao',
          ),
          FamilyMember(
            name: 'Arvel',
            roleKey: 'family_role_grandson',
            parentName: 'Lorie Salvador',
          ),
          FamilyMember(
            name: 'Aivan',
            roleKey: 'family_role_grandson',
            parentName: 'Lorie Salvador',
          ),
          FamilyMember(
            name: 'Honey',
            roleKey: 'family_role_granddaughter',
            parentName: 'Lorie Salvador',
          ),
          FamilyMember(
            name: 'Daniel',
            roleKey: 'family_role_grandson',
            parentName: 'Lorie Salvador',
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
