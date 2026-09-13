import 'package:flutter/material.dart';
import 'package:nita/core/localization/translations_en.dart';
import 'package:nita/core/localization/translations_tl.dart';
import 'package:nita/core/localization/translations_bi.dart';

enum AppLanguage { english, tagalog, bicol }

/// Drives which language `t()` looks strings up in. The actual translation
/// data lives in translations_en.dart / translations_tl.dart /
/// translations_bi.dart, this class is state + lookup logic only.
class LanguageProvider extends ChangeNotifier {
  /// Direct access to the translation maps (handy for tests and the
  /// debug key-sync check).
  static Map<String, String> get en => translationsEn;
  static Map<String, String> get tl => translationsTl;
  static Map<String, String> get bi => translationsBi;

  AppLanguage _language = AppLanguage.tagalog;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  bool get isEnglish => _language == AppLanguage.english;
  bool get isTagalog => _language == AppLanguage.tagalog;
  bool get isBicol => _language == AppLanguage.bicol;

  /// Looks up [key] in the active language map. Placeholders like
  /// `{count}` are substituted from [params] (e.g. `t('memories_count',
  /// {'count': '6'})`). Unknown keys fall back to the key itself.
  String t(String key, [Map<String, String>? params]) {
    final map = switch (_language) {
      AppLanguage.english => translationsEn,
      AppLanguage.tagalog => translationsTl,
      AppLanguage.bicol => translationsBi,
    };
    var text = map[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }

  /// Debug-only check: confirms en/tl/bi all define the exact same set of
  /// translation keys. Call this once (e.g. in main() before runApp, guarded
  /// by `if (kDebugMode)`) to catch missing translations before they ship
  /// as a raw key like 'gallery_search_hint' showing up on screen.
  static void debugCheckTranslationKeysMatch() {
    final enKeys = translationsEn.keys.toSet();
    final tlKeys = translationsTl.keys.toSet();
    final biKeys = translationsBi.keys.toSet();
    final allKeys = {...enKeys, ...tlKeys, ...biKeys};

    final missingFromEn = allKeys.difference(enKeys);
    final missingFromTl = allKeys.difference(tlKeys);
    final missingFromBi = allKeys.difference(biKeys);

    if (missingFromEn.isEmpty &&
        missingFromTl.isEmpty &&
        missingFromBi.isEmpty) {
      debugPrint('✓ LanguageProvider: all translation maps are in sync.');
      return;
    }
    if (missingFromEn.isNotEmpty) {
      debugPrint('⚠ Missing from en: $missingFromEn');
    }
    if (missingFromTl.isNotEmpty) {
      debugPrint('⚠ Missing from tl: $missingFromTl');
    }
    if (missingFromBi.isNotEmpty) {
      debugPrint('⚠ Missing from bi: $missingFromBi');
    }
  }
}
