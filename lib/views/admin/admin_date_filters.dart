part of 'admin_page.dart';

/// Shared date-filter card for the Messages, Visitors, and Private tabs: a
/// paper card with a calendar icon, "Filter by date" caption, bold range
/// summary, chevron to collapse, and quick pills (Today / Week /
/// Month & Year). The selected pill is dark brown with white text. "Week"
/// shows a month calendar where tapping any day selects its whole week row
/// at once; "Month & Year" shows a month grid (with year navigation) for
/// picking the month directly.
class _DatePillFilterCard extends StatelessWidget {
  final _DatePill pill;
  final String rangeLabel;
  final bool expanded;
  final int shown;
  final int total;
  final String unit;
  final bool filtered;
  final VoidCallback onToggle;
  final ValueChanged<_DatePill> onSelect;
  final VoidCallback onClear;
  final int weekYear;
  final int weekMonth;
  final int weekWeek;
  final void Function(int year, int month, int week) onPickWeek;
  final int monthYear;
  final int monthMonth;
  final void Function(int year, int month) onPickMonth;

  const _DatePillFilterCard({
    required this.pill,
    required this.rangeLabel,
    required this.expanded,
    required this.shown,
    required this.total,
    required this.unit,
    required this.filtered,
    required this.onToggle,
    required this.onSelect,
    required this.onClear,
    required this.weekYear,
    required this.weekMonth,
    required this.weekWeek,
    required this.onPickWeek,
    required this.monthYear,
    required this.monthMonth,
    required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mistPaper,
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: AppColors.warmDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by date',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rangeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Today',
                    selected: pill == _DatePill.today,
                    onTap: () => onSelect(_DatePill.today),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Week',
                    selected: pill == _DatePill.week,
                    onTap: () => onSelect(_DatePill.week),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Month & Year',
                    selected: pill == _DatePill.month,
                    onTap: () => onSelect(_DatePill.month),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    filtered
                        ? 'Showing $shown of $total'
                        : '$total $unit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (filtered)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmDeep,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (pill == _DatePill.week) ...[
              const SizedBox(height: 12),
              _WeekCalendar(
                year: weekYear,
                month: weekMonth,
                week: weekWeek,
                onPick: onPickWeek,
              ),
            ],
            if (pill == _DatePill.month) ...[
              const SizedBox(height: 12),
              _MonthPicker(
                year: monthYear,
                month: monthMonth,
                onPick: onPickMonth,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// One quick-pill inside [_DatePillFilterCard]. Selected = dark brown fill
/// with white text; unselected = cream fill with a stone border.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.warmDark : AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.warmDark
                : AppColors.stoneBorder.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

/// Month calendar for week picking: tapping any day selects its whole
/// week-of-month row at once (days 1-7 = week 1, 8-14 = week 2, ...), so a
/// single day can never be picked on its own. The picked row is painted as
/// one continuous pill, matching the reference design.
class _WeekCalendar extends StatefulWidget {
  final int year;
  final int month;
  final int week;
  final void Function(int year, int month, int week) onPick;

  const _WeekCalendar({
    required this.year,
    required this.month,
    required this.week,
    required this.onPick,
  });

  @override
  State<_WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<_WeekCalendar> {
  late int _viewYear;
  late int _viewMonth;

  /// Browsable bounds: Jan 2020 through Dec of the current year.
  static int get _maxYear => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _viewYear = widget.year;
    _viewMonth = widget.month;
  }

  @override
  void didUpdateWidget(_WeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reselected = widget.year != oldWidget.year ||
        widget.month != oldWidget.month ||
        widget.week != oldWidget.week;
    if (reselected &&
        (widget.year != _viewYear || widget.month != _viewMonth)) {
      _viewYear = widget.year;
      _viewMonth = widget.month;
    }
  }

  bool get _canPrev => _viewYear > 2020 || _viewMonth > 1;
  bool get _canNext =>
      _viewYear < _maxYear || (_viewYear == _maxYear && _viewMonth < 12);

  void _step(int delta) {
    var m = _viewMonth + delta;
    var y = _viewYear;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    if (y < 2020 || y > _maxYear) return;
    setState(() {
      _viewYear = y;
      _viewMonth = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _adminDaysInMonth(_viewYear, _viewMonth);
    final weekCount = _adminWeekCount(_viewYear, _viewMonth);
    final viewingPickedMonth =
        _viewYear == widget.year && _viewMonth == widget.month;
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _canPrev ? () => _step(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: AppColors.warmDeep,
                disabledColor: AppColors.muted.withValues(alpha: 0.4),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Expanded(
                child: Text(
                  '${_adminMonthsFull[_viewMonth - 1]} $_viewYear',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmDeep,
                  ),
                ),
              ),
              IconButton(
                onPressed: _canNext ? () => _step(1) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: AppColors.warmDeep,
                disabledColor: AppColors.muted.withValues(alpha: 0.4),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in dayNames)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var w = 1; w <= weekCount; w++) _weekRow(w, days, viewingPickedMonth),
        ],
      ),
    );
  }

  /// One week row: leading/trailing out-of-month days greyed, the picked
  /// row painted as a single pill. Tapping any in-month day picks the row.
  Widget _weekRow(int w, int days, bool viewingPickedMonth) {
    final startDay = (w - 1) * 7 + 1;
    final endDay = startDay + 6 > days ? days : startDay + 6;
    final offset = w == 1 ? DateTime(_viewYear, _viewMonth, 1).weekday % 7 : 0;
    final highlighted = viewingPickedMonth && w == widget.week;
    final cells = <Widget>[];
    if (offset > 0) {
      final prevDays = _adminDaysInMonth(
        _viewMonth == 1 ? _viewYear - 1 : _viewYear,
        _viewMonth == 1 ? 12 : _viewMonth - 1,
      );
      for (var i = 0; i < offset; i++) {
        cells.add(_dayCell('${prevDays - offset + 1 + i}'));
      }
    }
    for (var d = startDay; d <= endDay; d++) {
      cells.add(
        _dayCell(
          '$d',
          inMonth: true,
          highlighted: highlighted,
          first: d == startDay,
          last: d == endDay,
          bold: highlighted,
          onTap: () => widget.onPick(_viewYear, _viewMonth, w),
        ),
      );
    }
    var nextDay = 1;
    while (cells.length < 7) {
      cells.add(_dayCell('${nextDay++}'));
    }
    return Row(children: cells);
  }

  Widget _dayCell(
    String text, {
    bool inMonth = false,
    bool highlighted = false,
    bool first = false,
    bool last = false,
    bool bold = false,
    VoidCallback? onTap,
  }) {
    final inner = Container(
      height: 34,
      alignment: Alignment.center,
      decoration: highlighted
          ? BoxDecoration(
              color: AppColors.warmDark,
              borderRadius: BorderRadius.horizontal(
                left: first ? const Radius.circular(17) : Radius.zero,
                right: last ? const Radius.circular(17) : Radius.zero,
              ),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: highlighted
              ? Colors.white
              : inMonth
                  ? AppColors.textDark
                  : AppColors.muted.withValues(alpha: 0.5),
        ),
      ),
    );
    if (onTap == null) return Expanded(child: inner);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: inner,
      ),
    );
  }
}

/// Month grid for month picking: a year navigator plus the 12 months.
/// Tapping a month selects the whole month at once. Same card styling as
/// [_WeekCalendar].
class _MonthPicker extends StatefulWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onPick;

  const _MonthPicker({
    required this.year,
    required this.month,
    required this.onPick,
  });

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _viewYear;

  static int get _maxYear => DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _viewYear = widget.year;
  }

  @override
  void didUpdateWidget(_MonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reselected = widget.year != oldWidget.year ||
        widget.month != oldWidget.month;
    if (reselected && widget.year != _viewYear) {
      _viewYear = widget.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _viewYear > 2020
                    ? () => setState(() => _viewYear -= 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: AppColors.warmDeep,
                disabledColor: AppColors.muted.withValues(alpha: 0.4),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Expanded(
                child: Text(
                  '$_viewYear',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warmDeep,
                  ),
                ),
              ),
              IconButton(
                onPressed: _viewYear < _maxYear
                    ? () => setState(() => _viewYear += 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: AppColors.warmDeep,
                disabledColor: AppColors.muted.withValues(alpha: 0.4),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 38,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final m = i + 1;
              final selected =
                  _viewYear == widget.year && m == widget.month;
              return GestureDetector(
                onTap: () => widget.onPick(_viewYear, m),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.warmDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: selected
                          ? AppColors.warmDark
                          : AppColors.stoneBorder.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    _adminMonthsShort[m - 1],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
