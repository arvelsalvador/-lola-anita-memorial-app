import 'package:flutter/material.dart';
import 'package:nita/Pages/Home/Model/home_model.dart';

class HomeController extends ChangeNotifier {
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  // ── Identity data shared across all pages ─────────────────────────────────
  // Edit this block to personalise the app.
  static const HomeModel grandmother = HomeModel(
    name: 'Anita Daiz Lumbao',
    initial: 'L',
    birthYear: 1940,
    passingYear: 2025,
    tagline: 'Beloved grandmother, keeper of stories',
  );
}
