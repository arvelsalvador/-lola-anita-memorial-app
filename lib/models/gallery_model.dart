class GalleryImageItem {
  final String path;
  final String group;
  final String label;

  /// Localization keys resolved via `LanguageProvider.t(...)`. Populated by
  /// the filename parser in gallery_page.dart. When null, the widgets fall
  /// back to 'loc_lipa' / 'date_1'.
  final String? location;
  final String? date;

  GalleryImageItem({
    required this.path,
    required this.group,
    required this.label,
    this.location,
    this.date,
  });
}
