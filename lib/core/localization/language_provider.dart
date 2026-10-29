import 'package:flutter/material.dart';
import 'package:nita/core/localization/translations_en.dart';
import 'package:nita/core/localization/translations_tl.dart';
import 'package:nita/core/localization/translations_bi.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// SharedPreferences key the chosen language code ('en' | 'tl' | 'bi')
  /// is stored under. Written by the visitor gate (visitor_gate_form)
  /// and by [setLanguage]; read back on startup so a returning visitor
  /// no longer resets to Tagalog.
  static const String savedLanguageKey = 'visitor_lang';

  AppLanguage _language = AppLanguage.tagalog;

  LanguageProvider() {
    // Fire-and-forget restore: the constructor can't await, so the
    // saved choice applies a moment after startup and notifies
    // listeners (missing key = keep the Tagalog default).
    _restoreSavedLanguage();
  }

  /// Reads [savedLanguageKey] and applies it. Missing or unrecognized
  /// value = keep the current default; a read failure never throws.
  Future<void> _restoreSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      final restored = switch (prefs.getString(savedLanguageKey)) {
        'en' => AppLanguage.english,
        'tl' => AppLanguage.tagalog,
        'bi' => AppLanguage.bicol,
        _ => null,
      };
      if (restored == null || restored == _language) return;
      _language = restored;
      notifyListeners();
    } catch (e) {
      debugPrint('LanguageProvider: could not restore saved language ($e)');
    }
  }

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    // Persist the choice (fire-and-forget; failures never break the UI).
    saveLanguageCode(_codeOf(lang));
  }

  /// Persists [code] ('en' | 'tl' | 'bi') under [savedLanguageKey].
  /// Never throws — a failed write only debugPrints and the app keeps
  /// running with the in-memory language.
  static Future<void> saveLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(savedLanguageKey, code);
    } catch (e) {
      debugPrint('LanguageProvider: could not persist language ($e)');
    }
  }

  String _codeOf(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'en',
        AppLanguage.tagalog => 'tl',
        AppLanguage.bicol => 'bi',
      };

  bool get isEnglish => _language == AppLanguage.english;
  bool get isTagalog => _language == AppLanguage.tagalog;
  bool get isBicol => _language == AppLanguage.bicol;

  /// Looks up [key] in the active language map. Placeholders like
  /// `{count}` are substituted from [params] (e.g. `t('memories_count',
  /// {'count': '6'})`). Falls back to English, then to the key itself
  /// so a missing translation never blanks the UI.
  String t(String key, [Map<String, String>? params]) {
    final map = switch (_language) {
      AppLanguage.english => translationsEn,
      AppLanguage.tagalog => translationsTl,
      AppLanguage.bicol => translationsBi,
    };
    var text = map[key] ?? translationsEn[key] ?? key;
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
