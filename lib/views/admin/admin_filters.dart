part of 'admin_page.dart';

/// One reported target with all its reports + resolved message preview.
class _ReportedGroup {
  final String targetId;
  final String targetKind;
  final List<AdminReportRow> reports;
  String? authorName;
  String? message;
  DateTime? messageAt;
  String parentPostId;

  _ReportedGroup({
    required this.targetId,
    required this.targetKind,
    required this.reports,
  }) : parentPostId = '';

  DateTime get latest =>
      reports.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
}

/// Initials for the avatar circle ("Juan Dela Cruz" -> "JD").
String _adminInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'A';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

/// Deterministic pastel avatar fill from the memorial palette.
Color _adminAvatarColor(String name) {
  const options = [
    AppColors.goldLight,
    AppColors.roseLight,
    AppColors.mistPaper,
  ];
  var hash = 0;
  for (final unit in name.trim().toLowerCase().codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return options[hash % options.length].withValues(alpha: 0.6);
}

String _adminDate(DateTime dt) {
  final local = dt.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year}';
}

String _adminDateTime(DateTime dt) {
  final local = dt.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year}, $hh:$mi';
}

/// Month labels for the Visitors date filter (English: the admin page is
/// English-only).
const List<String> _adminMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _adminMonthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Range snapped to whole days: start 00:00, end 23:59:59.999, so a row
/// created any time on the end day is included.
DateTimeRange _adminDayRange(DateTime start, DateTime end) {
  return DateTimeRange(
    start: DateTime(start.year, start.month, start.day),
    end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
  );
}

int _adminDaysInMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day;

/// Weeks in a month, counting day 1-7 as week 1, 8-14 as week 2, etc.
int _adminWeekCount(int year, int month) =>
    ((_adminDaysInMonth(year, month) - 1) ~/ 7) + 1;

/// Quick date-filter pill shared by the Messages, Visitors, and Private
/// tabs. `custom` was removed; month picking covers years via its own
/// year navigator.
enum _DatePill { all, today, week, month }

/// Per-tab quick date-filter selection behind the shared pill card.
/// Each tab owns one instance so switching tabs never disturbs the
/// others. Week picking is whole-row ([weekYear]/[weekMonth]/[weekWeek],
/// days 1-7 = week 1, 8-14 = week 2, ...); month picking covers years
/// through its own navigator ([monthYear]/[monthMonth]).
class _DatePillFilter {
  _DatePill pill = _DatePill.all;
  bool expanded = true;
  late int weekYear;
  late int weekMonth;
  late int weekWeek;
  late int monthYear;
  late int monthMonth;

  _DatePillFilter() {
    // Capture `now` once so week/month fields can never disagree
    // when the clock ticks past midnight mid-construction.
    final now = DateTime.now();
    weekYear = now.year;
    weekMonth = now.month;
    weekWeek = ((now.day - 1) ~/ 7) + 1;
    monthYear = now.year;
    monthMonth = now.month;
  }

  /// Active range, or null for All.
  DateTimeRange? get range {
    final now = DateTime.now();
    switch (pill) {
      case _DatePill.all:
        return null;
      case _DatePill.today:
        return _adminDayRange(now, now);
      case _DatePill.week:
        final days = _adminDaysInMonth(weekYear, weekMonth);
        final startDay = (weekWeek - 1) * 7 + 1;
        final endDay = startDay + 6 > days ? days : startDay + 6;
        return _adminDayRange(
          DateTime(weekYear, weekMonth, startDay),
          DateTime(weekYear, weekMonth, endDay),
        );
      case _DatePill.month:
        return _adminDayRange(
          DateTime(monthYear, monthMonth, 1),
          DateTime(
            monthYear,
            monthMonth,
            _adminDaysInMonth(monthYear, monthMonth),
          ),
        );
    }
  }

  /// Header summary ("Oct 15 - Oct 21, 2026", "October 2026", "All dates").
  String get label {
    final r = range;
    if (r == null) return 'All dates';
    if (pill == _DatePill.month) {
      return '${_adminMonthsFull[monthMonth - 1]} $monthYear';
    }
    final s = r.start;
    final e = r.end;
    String mon(int m) => _adminMonthsShort[m - 1];
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return '${mon(s.month)} ${s.day}, ${s.year}';
    }
    if (s.year == e.year && s.month == e.month) {
      return '${mon(s.month)} ${s.day} - ${mon(e.month)} ${e.day}, ${s.year}';
    }
    if (s.year == e.year) {
      return '${mon(s.month)} ${s.day} - ${mon(e.month)} ${e.day}, ${s.year}';
    }
    return '${mon(s.month)} ${s.day}, ${s.year} - '
        '${mon(e.month)} ${e.day}, ${e.year}';
  }

  /// Any date pill active (search text is tracked separately per tab UI).
  bool get isActive => pill != _DatePill.all;

  /// True when [d] sits inside the selected range ("All" always matches).
  /// Compares in local time: Supabase timestamps arrive as UTC while the
  /// range is built from local midnights.
  bool matches(DateTime d) {
    final r = range;
    if (r == null) return true;
    final local = d.isUtc ? d.toLocal() : d;
    return !local.isBefore(r.start) && !local.isAfter(r.end);
  }

  /// Switch pills: week/month jump back to the current week/month, the
  /// inline calendars pick the rest.
  void select(_DatePill p) {
    final now = DateTime.now();
    pill = p;
    if (p == _DatePill.week) {
      weekYear = now.year;
      weekMonth = now.month;
      weekWeek = ((now.day - 1) ~/ 7) + 1;
    } else if (p == _DatePill.month) {
      monthYear = now.year;
      monthMonth = now.month;
    }
  }

  void pickWeek(int y, int m, int w) {
    weekYear = y;
    weekMonth = m;
    weekWeek = w;
  }

  void pickMonth(int y, int m) {
    monthYear = y;
    monthMonth = m;
  }

  void reset() => pill = _DatePill.all;
}

