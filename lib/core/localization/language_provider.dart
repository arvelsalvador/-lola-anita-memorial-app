import 'package:flutter/material.dart';

enum AppLanguage { english, tagalog }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  bool get isEnglish => _language == AppLanguage.english;
  bool get isTagalog => _language == AppLanguage.tagalog;

  String t(String key) {
    final map = _language == AppLanguage.english ? _en : _tl;
    return map[key] ?? key;
  }

  static const Map<String, String> _en = {
    'app_title': 'In Loving Memory',
    'nav_home': 'Home',
    'nav_gallery': 'Gallery',
    'nav_memories': 'Memories',
    'nav_tribute': 'Tribute',
    'nav_favorites': 'Favorites',
    'splash_quote': 'Those we love don\'t go away,\nThey walk beside us every day.',
    'splash_tap': 'Touch to enter',
    'hero_tagline': 'Beloved grandmother, keeper of stories',
    'section_her_words': 'Her words',
    'section_her_journey': 'Her journey',
    'section_about_her': 'About her',
    'section_cherished_memories': 'Cherished memories',
    'section_final_tribute': 'A final tribute',
    'section_words_family': 'Words from the family',
    'section_hobbies': 'Hobbies',
    'section_music': 'Music',
    'section_tv_shows': 'TV Shows',
    'section_more': 'More',
    'settings_language': 'Language',
    'settings_english': 'English',
    'settings_tagalog': 'Tagalog',
    'candle_light': 'Light a candle',
    'candle_virtual': 'Virtual candle lit in her memory',
    'no_images': 'No images found in gallery.\nTry a full restart after adding images.',
  };

  static const Map<String, String> _tl = {
    'app_title': 'Sa Mahal na Alaala',
    'nav_home': 'Tahanan',
    'nav_gallery': 'Galeri',
    'nav_memories': 'Mga Alaala',
    'nav_tribute': 'Pagkilala',
    'nav_favorites': 'Mga Paborito',
    'splash_quote': 'Ang mga natin ay hindi nawala,\nSilang laging kasama natin araw-araw.',
    'splash_tap': 'Pindutin upang pumasok',
    'hero_tagline': 'Minamahal na lola, tagapagkuwento ng mga alaala',
    'section_her_words': 'Kanyang mga salita',
    'section_her_journey': 'Kanyang paglalakbay',
    'section_about_her': 'Tungkol sa kanya',
    'section_cherished_memories': 'Mga mahalagang alaala',
    'section_final_tribute': 'Huling pagkilala',
    'section_words_family': 'Mga salita ng pamilya',
    'section_hobbies': 'Mga libangan',
    'section_music': 'Musika',
    'section_tv_shows': 'Mga palabas sa TV',
    'section_more': 'Higit pa',
    'settings_language': 'Wika',
    'settings_english': 'Ingles',
    'settings_tagalog': 'Tagalog',
    'candle_light': 'Magliwanag ng kandila',
    'candle_virtual': 'Virtual na kandila na nakasindi sa kanyang alaala',
    'no_images': 'Walang mga larawan sa galeri.\nSubukan ang buong pag-restart pagkatapos magdagdag ng mga larawan.',
  };
}
