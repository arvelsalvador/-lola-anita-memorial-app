/// Single source of truth for Lola Anita's memorial dates and family counts.
///
/// TODO(family): confirm the true birth/passing years. The story copy in all
/// three languages says she "lived 85 years", and the home timeline uses
/// 1940–2025 (2025-1940=85 ✓). The family page previously hardcoded
/// '1938–2022' (2022-1938=84 ✗). Until the family confirms, 1940–2025 is
/// used everywhere via these constants so the app can never show two
/// different year pairs again.
class Memorial {
  static const int birthYear = 1940;
  static const int passingYear = 2025;

  /// Display form for the family cover leaf (en-dash, matching prior style).
  static const String yearsLabel = '1940–2025';

  /// Lived years, matching `story_about` ("85 years") in all languages.
  static const int livedYears = passingYear - birthYear;

  /// Members actually modeled in [FamilyController.data]:
  /// 1 root + 3 siblings + 3 children + 8 grandchildren.
  /// TODO(family): nieces/nephews + other relatives were removed for
  /// redesign (`family_controller.dart` TODOs) — restore the 32-count only
  /// when that data ships again.
  static const int totalMembers = 15;
  static const int generations = 3;
  static const int siblingsCount = 3;
  static const int childrenCount = 3;
}
