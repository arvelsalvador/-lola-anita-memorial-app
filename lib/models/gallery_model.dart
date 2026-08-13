class GalleryImageItem {
  final String path;
  final String group;
  final String label;

  /// Optional — not yet populated by the filename parser in
  /// gallery_page.dart. Card falls back to [label] when these are null.
  /// Wire these up once you decide on a filename convention (e.g.
  /// `Bahay_LipaCityBatangas_2011-08-21.jpg`) or a separate manifest.
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
