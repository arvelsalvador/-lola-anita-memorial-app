import 'gallery_group.dart';

class GalleryImageItem {
  final String path;
  final GalleryGroup group;

  /// Localization keys resolved via `LanguageProvider.t(...)`. Populated by
  /// the filename parser in gallery_controller.dart. When null, the widgets
  /// fall back to 'loc_lipa' / 'date_1'.
  final String? location;
  final String? date;

  GalleryImageItem({
    required this.path,
    required this.group,
    this.location,
    this.date,
  });
}
