import 'package:nita/core/localization/language_provider.dart';

/// Pure derivation and formatting logic for display widgets.
///
/// Keeps string parsing (initials, flag/code labels) out of the widget
/// layer so views stay presentational and this logic is unit-testable.
class DisplayController {
  /// "Anita Daiz Lumbao" -> "AL" (first letter of the first and last
  /// words, or just the first letter for a single-word name).
  static String initialsOf(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last';
  }

  /// "1940 · 2025" — display formatting for a birth/passing year pair.
  static String yearsLabel(int birthYear, int passingYear) {
    return '$birthYear  ·  $passingYear';
  }

  /// Short language code shown inside the toggle: EN / TL / BC.
  static String languageCode(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => 'EN',
      AppLanguage.tagalog => 'TL',
      AppLanguage.bicol => 'BC',
    };
  }

  /// Flag glyph for the toggle: emoji for English/Tagalog, plain "BC"
  /// text for Bicol (which has no emoji flag).
  static String languageFlag(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => '🇬🇧',
      AppLanguage.tagalog => '🇵🇭',
      AppLanguage.bicol => 'BC',
    };
  }

  /// Whether [text] contains no emoji code points (plain letters/digits).
  /// Used to size a flag glyph differently from a plain text label.
  static bool isPlainText(String text) {
    return text.runes.every((r) => r < 0x1F000);
  }
}
