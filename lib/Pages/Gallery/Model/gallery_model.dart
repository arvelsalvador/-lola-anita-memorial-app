class GalleryModel {
  final List<PhotoItem> photos;
  const GalleryModel({required this.photos});
}

class PhotoItem {
  final String emoji;
  final String caption;
  final int colorHex1;
  final int colorHex2;

  const PhotoItem({
    required this.emoji,
    required this.caption,
    required this.colorHex1,
    required this.colorHex2,
  });
}
