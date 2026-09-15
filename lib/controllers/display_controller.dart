import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/display_utils.dart';

/// Backward-compatible facade over [DisplayUtils].
///
/// New code should import `core/utils/display_utils.dart` directly.
/// This wrapper is kept so existing `DisplayController.*` call sites
/// keep working during the architecture migration.
class DisplayController {
  static String initialsOf(String name) => DisplayUtils.initialsOf(name);

  static String yearsLabel(int birthYear, int passingYear) =>
      DisplayUtils.yearsLabel(birthYear, passingYear);

  static String languageCode(AppLanguage language) =>
      DisplayUtils.languageCode(language);

  static String languageFlag(AppLanguage language) =>
      DisplayUtils.languageFlag(language);

  static bool isPlainText(String text) => DisplayUtils.isPlainText(text);
}
