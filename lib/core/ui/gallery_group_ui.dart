import 'package:flutter/material.dart';
import 'package:nita/models/gallery_group.dart';

/// UI mapping for [GalleryGroup].
///
/// Kept out of the model layer so `models/` stays Flutter-material free
/// (pure data: `key` only). Views should import this extension for icons.
extension GalleryGroupUi on GalleryGroup {
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
