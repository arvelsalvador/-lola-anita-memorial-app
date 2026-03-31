import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'modern_gallery_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<GalleryImageItem>? _images;
  bool _didInit = false; // prevents running twice

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    try {
      debugPrint('=== LOADING GALLERY ===');
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final imagePaths = assetManifest
          .listAssets()
          .where(
            (String key) =>
                key.startsWith('assets/images/gallery/') &&
                (key.endsWith('.jpg') || key.endsWith('.png')),
          )
          .toList();

      debugPrint('Gallery images found: ${imagePaths.length}');
      imagePaths.sort();

      List<GalleryImageItem> items = imagePaths.map((path) {
        final fileName = path.split('/').last;
        final match = RegExp(r'^[A-Za-z]+').firstMatch(fileName);
        final group = match != null ? match.group(0)! : 'Other';
        final label = fileName
            .replaceAll(RegExp(r'[_\-.]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'\.[a-zA-Z]+$'), '')
            .trim();
        return GalleryImageItem(path: path, group: group, label: label);
      }).toList();

      if (mounted) setState(() => _images = items);

      // Precache first 9 images — safe here because context is ready
      if (mounted) {
        for (int i = 0; i < items.length && i < 9; i++) {
          await precacheImage(AssetImage(items[i].path), context);
        }
      }
    } catch (e) {
      debugPrint('=== GALLERY ERROR: $e ===');
      if (mounted) setState(() => _images = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_images!.isEmpty) {
      return const Center(
        child: Text(
          'No images found in gallery.\nTry a full restart after adding images.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ModernGalleryPage(images: _images!);
  }
}
