import 'package:flutter/material.dart';
import 'package:nita/core/gallery_assets.dart';
import 'package:nita/models/home_model.dart';

class MemoriesController extends ChangeNotifier {
  static const MemoriesModel data = MemoriesModel(
    memories: [
      MemoryItem(
        id: 'memory_1',
        icon: '🍚',
        titleKey: 'memory_1_title',
        bodyKey: 'memory_1_body',
        category: 'mem_filter_celebrations',
        decade: '1960s',
        photoCount: 14,
      ),
      MemoryItem(
        id: 'memory_2',
        icon: '🙏',
        titleKey: 'memory_2_title',
        bodyKey: 'memory_2_body',
        category: 'mem_filter_life',
        decade: '1970s',
        photoCount: 8,
      ),
      MemoryItem(
        id: 'memory_3',
        icon: '✂️',
        titleKey: 'memory_3_title',
        bodyKey: 'memory_3_body',
        category: 'mem_filter_life',
        decade: '1950s',
        photoCount: 9,
      ),
      MemoryItem(
        id: 'memory_4',
        icon: '🌺',
        titleKey: 'memory_4_title',
        bodyKey: 'memory_4_body',
        category: 'mem_filter_life',
        decade: '1980s',
        photoCount: 12,
      ),
      MemoryItem(
        id: 'memory_5',
        icon: '📻',
        titleKey: 'memory_5_title',
        bodyKey: 'memory_5_body',
        category: 'mem_filter_family',
        decade: '1990s',
        photoCount: 6,
      ),
      MemoryItem(
        id: 'memory_6',
        icon: '💌',
        titleKey: 'memory_6_title',
        bodyKey: 'memory_6_body',
        category: 'mem_filter_family',
        decade: '2000s',
        photoCount: 15,
      ),
    ],
  );

  String? _selectedCategory;
  int? _galleryCount;

  String? get selectedCategory => _selectedCategory;

  /// Real gallery photo count, loaded from the asset manifest so the stats
  /// pill and the feature card always reflect the actual gallery. Null
  /// while the manifest is still being read (shown as a loading placeholder).
  /// -1 means the read failed (shown as a dash instead of pulsing forever).
  int? get galleryCount => _galleryCount;

  /// All memories when no filter is selected, otherwise only the memories
  /// in the selected category.
  List<MemoryItem> get visibleMemories {
    if (_selectedCategory == null) return data.memories;
    return data.memories.where((m) => m.category == _selectedCategory).toList();
  }

  void selectCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

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
