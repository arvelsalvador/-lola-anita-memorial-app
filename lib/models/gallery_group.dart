import 'package:flutter/material.dart';

enum GalleryGroup {
  other,
  celebrations,
  bahay,
  family,
  care,
  gatherings,
  portraits,
  remembrances;

  String get key {
    switch (this) {
      case GalleryGroup.other:
        return 'group_other';
      case GalleryGroup.celebrations:
        return 'group_celebrations';
      case GalleryGroup.bahay:
        return 'group_bahay';
      case GalleryGroup.family:
        return 'group_family';
      case GalleryGroup.care:
        return 'group_care';
      case GalleryGroup.gatherings:
        return 'group_gatherings';
      case GalleryGroup.portraits:
        return 'group_portraits';
      case GalleryGroup.remembrances:
        return 'group_remembrances';
    }
  }

  IconData get icon {
    switch (this) {
      case GalleryGroup.other:
        return Icons.image_outlined;
      case GalleryGroup.celebrations:
        return Icons.cake_outlined;
      case GalleryGroup.bahay:
        return Icons.home_outlined;
      case GalleryGroup.family:
        return Icons.group_outlined;
      case GalleryGroup.care:
        return Icons.local_hospital_outlined;
      case GalleryGroup.gatherings:
        return Icons.people_outlined;
      case GalleryGroup.portraits:
        return Icons.person_outlined;
      case GalleryGroup.remembrances:
        return Icons.local_fire_department_outlined;
    }
  }
}
