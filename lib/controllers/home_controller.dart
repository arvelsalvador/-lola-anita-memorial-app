import 'package:flutter/material.dart';
import 'package:nita/core/constants/memorial.dart';
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

  // --- Story data (merged from story_controller.dart) ---
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
}
