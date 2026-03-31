import 'package:flutter/material.dart';
import 'modern_gallery_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<GalleryImageItem>? _images;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = manifestContent.isNotEmpty
        ? Map<String, dynamic>.from(jsonDecode(manifestContent))
        : {};

    final imagePaths = manifestMap.keys
        .where(
          (String key) =>
              key.startsWith('assets/images/gallery/') &&
              (key.endsWith('.jpg') || key.endsWith('.png')),
        )
        .toList();
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

    setState(() {
      _images = items;
    });

    // Precache first 9 visible images
    for (int i = 0; i < items.length && i < 9; i++) {
      await precacheImage(AssetImage(items[i].path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ModernGalleryPage(images: _images!);
  }
}
