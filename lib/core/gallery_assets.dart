import 'package:flutter/services.dart';

/// Support assets that happen to live in the gallery folder but are not
/// gallery photos: hero header background, memorial frame, profile photo,
/// and strays. Excluding them keeps them out of the grid, the chips, and
/// the photo counts.
const Set<String> gallerySupportAssets = {
  'Frame.jpg',
  'Frame.png',
  'memorial_header_background_raw.jpg',
  'Nanay_dp.jpg',
};

/// All gallery photo asset paths (sorted), excluding the support assets
/// above. Shared by the gallery page (the grid) and the memories page
/// (the "N larawan sa Galeri" counts).
Future<List<String>> loadGalleryPhotoPaths() async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final paths = assetManifest
      .listAssets()
      .where(
        (key) =>
            key.startsWith('assets/images/gallery/') &&
            (key.endsWith('.jpg') || key.endsWith('.png')),
      )
      .where((key) => !gallerySupportAssets.contains(key.split('/').last))
      .toList();
  paths.sort();
  return paths;
}
