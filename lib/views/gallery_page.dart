import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/widgets/gallery_widget.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<GalleryImageItem>? _images;
  bool _didInit = false;

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
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final imagePaths = assetManifest
          .listAssets()
          .where(
            (String key) =>
                key.startsWith('assets/images/gallery/') &&
                (key.endsWith('.jpg') || key.endsWith('.png')),
          )
          .toList();

      imagePaths.sort();

      final items = imagePaths.map((path) {
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

      if (mounted) {
        for (int i = 0; i < items.length && i < 9; i++) {
          await precacheImage(AssetImage(items[i].path), context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _images = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    if (_images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_images!.isEmpty) {
      return Center(
        child: Text(
          lang.t('no_images'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GalleryGridView(images: _images!);
  }
}
