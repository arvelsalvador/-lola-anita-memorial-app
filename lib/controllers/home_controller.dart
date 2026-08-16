import 'package:flutter/material.dart';
import 'package:nita/models/home_model.dart';

class HomeController extends ChangeNotifier {
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (_selectedTab != index && index >= 0 && index <= 4) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  static const HomeModel grandmother = HomeModel(
    name: 'Anita Daiz Lumbao',
    initial: 'A',
    birthYear: 1940,
    passingYear: 2025,
    tagline: 'Isang mahal na Ina, Lola, at haligi ng Pamilya',
  );
}
