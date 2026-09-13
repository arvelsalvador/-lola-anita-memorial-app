import 'package:flutter/material.dart';
import 'package:nita/core/gallery_assets.dart';
import 'package:nita/models/home_model.dart';

class MemoriesController extends ChangeNotifier {
  static const MemoriesModel data = MemoriesModel(
    memories: [
      MemoryItem(
        id: 'memory_1',
        icon: '🏠',
        titleKey: 'memory_1_title',
        bodyKey: 'memory_1_body',
        photoCount: 14,
        image: 'assets/images/Best Pictures/Bahay.jpg',
      ),
      MemoryItem(
        id: 'memory_2',
        icon: '👵',
        titleKey: 'memory_2_title',
        bodyKey: 'memory_2_body',
        photoCount: 8,
        image: 'assets/images/Best Pictures/Fullbody.jpg',
      ),
      MemoryItem(
        id: 'memory_3',
        icon: '💗',
        titleKey: 'memory_3_title',
        bodyKey: 'memory_3_body',
        photoCount: 9,
        image: 'assets/images/Best Pictures/Halik.jpg',
      ),
      MemoryItem(
        id: 'memory_4',
        icon: '🤲',
        titleKey: 'memory_4_title',
        bodyKey: 'memory_4_body',
        photoCount: 12,
        image: 'assets/images/Best Pictures/Kamay.jpg',
      ),
      MemoryItem(
        id: 'memory_5',
        icon: '💪',
        titleKey: 'memory_5_title',
        bodyKey: 'memory_5_body',
        photoCount: 6,
        image: 'assets/images/Best Pictures/Stolen.jpg',
      ),
      MemoryItem(
        id: 'memory_6',
        icon: '🎂',
        titleKey: 'memory_6_title',
        bodyKey: 'memory_6_body',
        photoCount: 15,
        image: 'assets/images/Best Pictures/Bday5.jpg',
      ),
      MemoryItem(
        id: 'memory_7',
        icon: '🕊️',
        titleKey: 'memory_7_title',
        bodyKey: 'memory_7_body',
        photoCount: 2,
        image: 'assets/images/Best Pictures/After death.jpg',
      ),
    ],
  );

  int? _galleryCount;

  /// Real gallery photo count, loaded from the asset manifest so the stats
  /// pill and the feature card always reflect the actual gallery. Null
  /// while the manifest is still being read (shown as a loading placeholder).
  /// -1 means the read failed (shown as a dash instead of pulsing forever).
  int? get galleryCount => _galleryCount;

  Future<void> loadGalleryCount() async {
    try {
      final paths = await loadGalleryPhotoPaths();
      if (_galleryCount != paths.length) {
        _galleryCount = paths.length;
        notifyListeners();
      }
    } catch (_) {
      // -1 marks a failed load, distinct from null ("still loading"), so
      // the UI can stop pulsing and show a dash instead of waiting forever.
      if (_galleryCount != -1) {
        _galleryCount = -1;
        notifyListeners();
      }
    }
  }
}
