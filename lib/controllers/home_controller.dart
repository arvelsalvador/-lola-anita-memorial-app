import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nita/core/constants/memorial.dart';
import 'package:nita/core/utils/gallery_assets.dart';
import 'package:nita/models/home_model.dart';

class HomeController extends ChangeNotifier {
  static const int tabCount = 5;

  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (_selectedTab != index && index >= 0 && index < tabCount) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  static const HomeModel grandmother = HomeModel(
    name: 'Anita Daiz Lumbao',
    initial: 'A',
    birthYear: Memorial.birthYear,
    passingYear: Memorial.passingYear,
  );

  // --- Story data ---
  // Favorites copy lives in translations as `story_favorites` (all 3
  // languages) so every surface stays translatable per product principle 4.
  static const StoryModel data = StoryModel(
    quoteKey: 'story_quote',
    quoteAttributionKey: 'story_quote_attribution',
    aboutKey: 'story_about',
    favoritesKey: 'story_favorites',
    // Years come from Memorial so home/family can never drift apart.
    // (String interpolation of a const int stays const.)
    timeline: [
      LifeEvent(
        year: '${Memorial.birthYear}',
        titleKey: 'timeline_birth_title',
        descriptionKey: 'timeline_birth_desc',
      ),
      LifeEvent(
        year: '1961',
        titleKey: 'timeline_marriage_title',
        descriptionKey: 'timeline_marriage_desc',
      ),
      LifeEvent(
        year: '1975',
        titleKey: 'timeline_first_apo_title',
        descriptionKey: 'timeline_first_apo_desc',
      ),
      LifeEvent(
        year: '1998',
        titleKey: 'timeline_anniversary_title',
        descriptionKey: 'timeline_anniversary_desc',
      ),
      LifeEvent(
        year: '${Memorial.passingYear}',
        titleKey: 'timeline_passing_title',
        descriptionKey: 'timeline_passing_desc',
        isLast: true,
      ),
    ],
  );

  // --- Cherished memories (Home tab section) ---
  // Moved here from the old MemoriesController so everything for Home
  // lives in one place. Used by views/home/home_story_memories.dart.
  static const MemoriesModel memoriesData = MemoriesModel(
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
      final paths = await loadGalleryPhotoPaths().timeout(
        const Duration(seconds: 10),
      );
      if (_galleryCount != paths.length) {
        _galleryCount = paths.length;
        notifyListeners();
      }
    } catch (e) {
      // -1 marks a failed load, distinct from null ("still loading"), so
      // the UI can stop pulsing and show a dash instead of waiting forever.
      debugPrint('[Home] gallery count failed: $e');
      if (_galleryCount != -1) {
        _galleryCount = -1;
        notifyListeners();
      }
    }
  }
}
