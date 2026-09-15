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
}
