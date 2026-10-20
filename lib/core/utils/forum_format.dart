/// Pure date/initials formatting for the forum cards.
///
/// Extracted from `ForumPostCard` — same output, no widget dependency.
/// EN uses Jan/Feb/..., TL+BI use Ene/Peb/... (Filipino short months).
class ForumFormat {
  ForumFormat._();

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsFil = [
    'Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun',
    'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis',
  ];

  /// Relative first (<1h just now, <24h hours, <7d days), then [fallback].
  /// `justNow`, `hoursAgo(count)`, `daysAgo(count)` are the already-
  /// translated strings (EN/TL/BI via `lang.t`). Future timestamps
  /// fall back to just now.
  static String relative(
    DateTime dateTime, {
    required String fallback,
    required String justNow,
    required String Function(int count) hoursAgo,
    required String Function(int count) daysAgo,
  }) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());
    if (diff.isNegative || diff.inMinutes < 60) return justNow;
    if (diff.inHours < 24) return hoursAgo(diff.inHours);
    if (diff.inDays < 7) return daysAgo(diff.inDays);
    return fallback;
  }

  /// Full date for the main post: "Kanina lamang" / "3 oras..." / "Okt 6, 2026".
  static String exact(
    DateTime dateTime, {
    required bool english,
    required String justNow,
    required String Function(int count) hoursAgo,
    required String Function(int count) daysAgo,
  }) {
    final local = dateTime.toLocal();
    final month = (english ? _monthsEn : _monthsFil)[local.month - 1];
    final fallback = '$month ${local.day}, ${local.year}';
    return relative(
      dateTime,
      fallback: fallback,
      justNow: justNow,
      hoursAgo: hoursAgo,
      daysAgo: daysAgo,
    );
  }

  /// Short date for replies: "Kanina lamang" / "Okt 7".
  static String short(
    DateTime dateTime, {
    required bool english,
    required String justNow,
    required String Function(int count) hoursAgo,
    required String Function(int count) daysAgo,
  }) {
    final local = dateTime.toLocal();
    final month = (english ? _monthsEn : _monthsFil)[local.month - 1];
    final fallback = '$month ${local.day}';
    return relative(
      dateTime,
      fallback: fallback,
      justNow: justNow,
      hoursAgo: hoursAgo,
      daysAgo: daysAgo,
    );
  }

  /// "Juan Dela Cruz" -> "JD", "Maria" -> "M", "" -> "A".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
