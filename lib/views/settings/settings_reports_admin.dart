part of 'settings_page.dart';

/// Family-only moderation gate + admin page.
///
/// Hidden entry: tap the "Nanay Anita · Bersyon" footer 4 times within
/// 2 seconds, enter the family PIN, then review reports, messages,
/// visitors, and private candle messages.
///
/// The PIN itself lives in [AdminCredential] (shared with the database
/// verification from `supabase/pakikiramay_security.sql`).

/// Admin-page copy always renders in English, no matter which language the
/// app is set to. User-authored content (messages, names, addresses,
/// report details) is data and is never translated.
String _adminText(String key) => LanguageProvider.en[key] ?? key;

/// The PIN that currently opens the admin page: the family's own PIN
/// when one was saved, otherwise the built-in default. Delegates to
/// [AdminCredential] so the admin settings and the server-side PIN
/// verification (`supabase/pakikiramay_security.sql`) share one source.
Future<String> _effectiveAdminPin() => AdminCredential.effectivePin();

/// Shows the PIN prompt. On correct PIN, pushes [_ReportsAdminPage].
Future<void> showAdminPinDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _AdminPinDialog(),
  );
}

class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _wrong = false;
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _wrong = false;
    });
    final expected = await _effectiveAdminPin();
    if (!mounted) return;
    if (_pinController.text.trim() == expected) {
      Navigator.of(context).pop();
      Navigator.of(context).push(fadeRoute(const _ReportsAdminPage()));
    } else {
      setState(() {
        _checking = false;
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _adminText('admin_pin_title'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _adminText('admin_pin_subtitle'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: _adminText('admin_pin_hint'),
              counterText: '',
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              errorText: _wrong ? _adminText('admin_pin_wrong') : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_adminText('admin_pin_cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_adminText('admin_pin_open')),
        ),
      ],
    );
  }
}

/// Change-PIN dialog, opened from the lock button in [_AdminHeader].
/// Verifies the current PIN, then saves a new 6-digit family PIN
/// on this device. Returns true when the PIN was changed.
class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String? _errorKey;
  int _errorIndex = 2;
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isPin(String v) => RegExp(r'^\d{6}$').hasMatch(v.trim());

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final expected = await _effectiveAdminPin();
    if (!mounted) return;
    if (_currentCtrl.text.trim() != expected) {
      setState(() {
        _saving = false;
        _errorIndex = 0;
        _errorKey = 'admin_change_pin_wrong';
      });
      return;
    }
    if (!_isPin(_newCtrl.text) || !_isPin(_confirmCtrl.text)) {
      setState(() {
        _saving = false;
        _errorIndex = 1;
        _errorKey = 'admin_change_pin_invalid';
      });
      return;
    }
    if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() {
        _saving = false;
        _errorIndex = 2;
        _errorKey = 'admin_change_pin_mismatch';
      });
      return;
    }
    // Saves on-device AND re-hashes the PIN on the server so the
    // database-side verification (`pakikiramay_admin_change_pin`) stays
    // in sync with what this device expects.
    final synced = await AdminCredential.changePin(
      oldPin: _currentCtrl.text.trim(),
      newPin: _newCtrl.text.trim(),
    );
    if (!mounted) return;
    if (!synced) {
      setState(() {
        _saving = false;
        _errorIndex = 0;
        _errorKey = 'admin_report_action_failed';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _adminText('admin_change_pin_title'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.warmDark,
          height: 1.25,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pinField(
              controller: _currentCtrl,
            label: _adminText('admin_change_pin_current'),
            obscure: _obscureCurrent,
            onToggleEye: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
            errorText: _errorIndex == 0 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          _pinField(
            controller: _newCtrl,
            label: _adminText('admin_change_pin_new'),
            obscure: _obscureNew,
            onToggleEye: () =>
                setState(() => _obscureNew = !_obscureNew),
            errorText: _errorIndex == 1 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
          ),
          const SizedBox(height: 14),
          _pinField(
            controller: _confirmCtrl,
            label: _adminText('admin_change_pin_confirm'),
            obscure: _obscureConfirm,
            onToggleEye: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            errorText: _errorIndex == 2 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
          ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warmDeep,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(_adminText('admin_pin_cancel')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
              vertical: 12,
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(_adminText('admin_save')),
        ),
      ],
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleEye,
    required String? errorText,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      obscuringCharacter: '•',
      keyboardType: TextInputType.number,
      maxLength: 6,
      autofocus: autofocus,
      onSubmitted: (_) => _save(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        letterSpacing: 2,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          color: AppColors.muted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.warmDeep,
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleEye,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.warmMid,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.stoneBorder.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.warmDeep,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.roseDeep),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.roseDeep,
            width: 1.4,
          ),
        ),
        errorText: errorText,
      ),
    );
  }
}

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

class _ReportsAdminPage extends StatefulWidget {
  const _ReportsAdminPage();

  @override
  State<_ReportsAdminPage> createState() => _ReportsAdminPageState();
}

class _ReportsAdminPageState extends State<_ReportsAdminPage> {
  final ForumRepository _forumRepo = const ForumRepository();
  final VisitorRepository _visitorRepo = const VisitorRepository();
  final CondolenceRepository _candleRepo = const CondolenceRepository();

  int _tab = 0;
  bool _loading = true;
  bool _loadError = false;
  String _loadErrorDetail = '';
  List<_ReportedGroup> _groups = [];
  List<ForumPost> _posts = [];
  List<AdminVisitor> _visitors = [];
  List<AdminCandleMessage> _candle = [];
  final Set<String> _busy = {};
  // Per-tab search: switching tabs restores that tab's own query.
  final List<String> _tabQueries = ['', '', '', ''];
  final TextEditingController _searchController = TextEditingController();
  String get _query => _tabQueries[_tab];

  // Client pagination: how many rows each tab shows ("Load more" +30).
  final List<int> _visibleCount = [30, 30, 30, 30];

  // Bulk selection (Reports tab: dismiss/delete many at once).
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  /// Per-tab quick date filters (Messages / Visitors / Private). Each tab
  /// keeps its own [_DatePillFilter] so switching tabs never disturbs the
  /// others. All three tabs reuse the same pill card.
  final _DatePillFilter _messageDates = _DatePillFilter();
  final _DatePillFilter _visitorDates = _DatePillFilter();
  final _DatePillFilter _privateDates = _DatePillFilter();

  /// Reports-tab reason filter only: 0 = all, 1 = profanity,
  /// 2 = inappropriate, 3 = spam, 4 = other. Does not affect other tabs.
  int _reportReason = 0;
  RealtimeChannel? _adminChannel;
  int _realtimeDebounce = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeAdminRealtime();
  }

  @override
  void dispose() {
    _unsubscribeAdminRealtime();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
      _loadErrorDetail = '';
    });
    try {
      final results = await Future.wait([
        _forumRepo.fetchAdminReports(),
        _forumRepo.fetchPosts(),
        _visitorRepo.fetchAdminVisitors(),
        _candleRepo.fetchAdminMessages(),
      ]);
      if (!mounted) return;
      final reports = results[0] as List<AdminReportRow>;
      final posts = results[1] as List<ForumPost>;
      final groups = _buildGroups(reports, posts);
      setState(() {
        _posts = posts;
        _groups = groups;
        _visitors = results[2] as List<AdminVisitor>;
        _candle = results[3] as List<AdminCandleMessage>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
        _loadErrorDetail = _describeLoadError(e);
      });
    }
  }

  /// Human-readable load failure: offline vs permission vs unknown.
  /// Repos return [] on failure, this only runs when Future.wait throws.
  static String _describeLoadError(Object e) {
    final msg = e.toString().toLowerCase();
    if (!SupabaseConfig.isConfigured) return 'Supabase is not configured.';
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('failed host') ||
        msg.contains('connection')) {
      return 'No connection. Check internet and retry.';
    }
    if (msg.contains('permission') ||
        msg.contains('rls') ||
        msg.contains('policy') ||
        msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized')) {
      return 'No permission. Check Supabase SELECT policies.';
    }
    return 'Load failed: $e';
  }

  /// Silent refresh for one tab only (avoids full 4-table reload).
  Future<void> _refreshReportsSilent() async {
    try {
      final reports = await _forumRepo.fetchAdminReports();
      final posts = await _forumRepo.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _groups = _buildGroups(reports, posts);
      });
    } catch (_) {}
  }

  Future<void> _subscribeAdminRealtime() async {
    if (!SupabaseConfig.isConfigured || _adminChannel != null) return;
    try {
      final channel =
          Supabase.instance.client.channel('admin-reports-feed');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: _onRemotePostUpdated,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: _onRemoteReplyUpdated,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: ForumRepository.messagesTable,
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: ForumRepository.repliesTable,
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: ForumRepository.reportsTable,
            callback: (_) => _scheduleRealtimeRefresh(),
          )
          .subscribe();
      _adminChannel = channel;
    } catch (e) {
      debugPrint('Admin realtime skipped: $e');
    }
  }

  void _onRemotePostUpdated(PostgresChangePayload payload) {
    if (!mounted) return;
    final record = payload.newRecord;
    final id = record['id']?.toString() ?? '';
    final message = (record['message'] as String? ?? '').trim();
    if (id.isEmpty || message.isEmpty) {
      _scheduleRealtimeRefresh();
      return;
    }
    setState(() {
      _posts = _posts
          .map((p) => p.id == id ? p.copyWith(message: message) : p)
          .toList();
      for (final g in _groups) {
        if (g.targetId == id) g.message = message;
      }
    });
  }

  void _onRemoteReplyUpdated(PostgresChangePayload payload) {
    if (!mounted) return;
    final record = payload.newRecord;
    final id = record['id']?.toString() ?? '';
    final message = (record['message'] as String? ?? '').trim();
    if (id.isEmpty || message.isEmpty) {
      _scheduleRealtimeRefresh();
      return;
    }
    setState(() {
      _posts = _posts
          .map(
            (p) => p.copyWith(
              replies: p.replies
                  .map((r) =>
                      r.id == id ? r.copyWith(message: message) : r)
                  .toList(),
            ),
          )
          .toList();
      for (final g in _groups) {
        if (g.targetId == id) g.message = message;
      }
    });
  }

  void _scheduleRealtimeRefresh() {
    final token = ++_realtimeDebounce;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || token != _realtimeDebounce) return;
      _refreshReportsSilent();
    });
  }

  Future<void> _unsubscribeAdminRealtime() async {
    final channel = _adminChannel;
    _adminChannel = null;
    if (channel == null) return;
    try {
      await Supabase.instance.client.removeChannel(channel);
    } catch (e) {
      debugPrint('Admin realtime unsubscribe skipped: $e');
    }
  }

  static List<_ReportedGroup> _buildGroups(
    List<AdminReportRow> reports,
    List<ForumPost> posts,
  ) {
    final postsById = {for (final p in posts) p.id: p};
    final replyById = <String, ForumReply>{};
    for (final p in posts) {
      for (final r in p.replies) {
        replyById[r.id] = r;
      }
    }
    final byTarget = <String, List<AdminReportRow>>{};
    for (final row in reports) {
      byTarget.putIfAbsent(row.targetId, () => []).add(row);
    }
    final groups = <_ReportedGroup>[];
    for (final entry in byTarget.entries) {
      final first = entry.value.first;
      final g = _ReportedGroup(
        targetId: entry.key,
        targetKind: first.targetKind,
        reports: entry.value,
      );
      if (first.targetKind == 'reply') {
        final reply = replyById[entry.key];
        if (reply != null) {
          g.authorName = reply.authorName;
          g.message = reply.message;
          g.messageAt = reply.createdAt;
          g.parentPostId = reply.postId;
        }
      } else {
        final post = postsById[entry.key];
        if (post != null) {
          g.authorName = post.authorName;
          g.message = post.message;
          g.messageAt = post.createdAt;
        }
      }
      groups.add(g);
    }
    groups.sort((a, b) => b.latest.compareTo(a.latest));
    return groups;
  }

  String _reasonLabel(LanguageProvider lang, String reason) {
    return switch (reason) {
      'profanity' => _adminText('forum_report_reason_profanity'),
      'inappropriate' => _adminText('forum_report_reason_inappropriate'),
      'spam' => _adminText('forum_report_reason_spam'),
      _ => _adminText('forum_report_reason_other'),
    };
  }

  void _snack(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_adminText(key))),
    );
  }

  Future<void> _openChangePin() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePinDialog(),
    );
    if (changed == true && mounted) _snack('admin_change_pin_saved');
  }

  Future<String?> _editTextDialog({
    required String title,
    required String initial,
    int maxLength = 1000,
  }) async {
    final controller = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_adminText('admin_pin_cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop(controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmDark,
                  foregroundColor: Colors.white,
                ),
                child: Text(_adminText('admin_save')),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirm({
    required String titleKey,
    required String bodyKey,
    required String confirmKey,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(_adminText(titleKey)),
        content: Text(_adminText(bodyKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_adminText('admin_pin_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor:
                  destructive ? AppColors.roseDeep : AppColors.textDark,
            ),
            child: Text(_adminText(confirmKey)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // ---- reports tab actions (in-place, no full reload) ----

  void _removeGroupLocally(String targetId) {
    _groups.removeWhere((g) => g.targetId == targetId);
    _posts = _posts
        .map((p) {
          if (p.id == targetId) return null;
          final replies =
              p.replies.where((r) => r.id != targetId).toList();
          if (replies.length == p.replies.length) return p;
          return p.copyWith(replies: replies);
        })
        .whereType<ForumPost>()
        .toList();
    _selectedIds.remove(targetId);
    if (_groups.isEmpty) _selectMode = false;
  }

  Future<void> _confirmDeleteGroup(_ReportedGroup g) async {
    final ok = await _confirm(
      titleKey: 'admin_delete_confirm_title',
      bodyKey: 'admin_delete_confirm_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(g.targetId));
    final saved = await _forumRepo.adminDeleteTarget(
      targetId: g.targetId,
      targetKind: g.targetKind,
      parentPostId: g.parentPostId,
    );
    if (!mounted) return;
    setState(() {
      _busy.remove(g.targetId);
      if (saved) _removeGroupLocally(g.targetId);
    });
    _snack(saved ? 'admin_report_deleted' : 'admin_report_action_failed');
    if (saved) {
      await AdminAuditLog.log(
          'delete ${g.targetKind}', g.message ?? g.targetId);
    }
  }

  Future<void> _confirmDismissGroup(_ReportedGroup g) async {
    final ok = await _confirm(
      titleKey: 'admin_dismiss_confirm_title',
      bodyKey: 'admin_dismiss_confirm_body',
      confirmKey: 'admin_confirm_dismiss',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(g.targetId));
    final saved = await _forumRepo.dismissReports(g.targetId);
    if (!mounted) return;
    setState(() {
      _busy.remove(g.targetId);
      if (saved) _removeGroupLocally(g.targetId);
    });
    _snack(saved ? 'admin_report_dismissed' : 'admin_report_action_failed');
    if (saved) {
      await AdminAuditLog.log('dismiss reports', g.message ?? g.targetId);
    }
  }

  /// Bulk dismiss/delete for selected report groups.
  Future<void> _bulkDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await _confirm(
      titleKey: 'admin_delete_confirm_title',
      bodyKey: 'admin_delete_confirm_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final ids = _selectedIds.toList();
    setState(() => _busy.addAll(ids));
    var done = 0;
    for (final id in ids) {
      _ReportedGroup? g;
      try {
        g = _groups.firstWhere((e) => e.targetId == id);
      } catch (_) {
        g = null;
      }
      if (g == null) continue;
      final saved = await _forumRepo.adminDeleteTarget(
        targetId: g.targetId,
        targetKind: g.targetKind,
        parentPostId: g.parentPostId,
      );
      if (!mounted) return;
      if (saved) {
        done++;
        setState(() => _removeGroupLocally(id));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy.removeAll(ids);
      _selectedIds.clear();
      _selectMode = false;
    });
    _snack(done > 0 ? 'admin_report_deleted' : 'admin_report_action_failed');
    if (done > 0) await AdminAuditLog.log('bulk delete', '$done items');
  }

  Future<void> _bulkDismissSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await _confirm(
      titleKey: 'admin_dismiss_confirm_title',
      bodyKey: 'admin_dismiss_confirm_body',
      confirmKey: 'admin_confirm_dismiss',
    );
    if (!ok || !mounted) return;
    final ids = _selectedIds.toList();
    setState(() => _busy.addAll(ids));
    var done = 0;
    for (final id in ids) {
      final saved = await _forumRepo.dismissReports(id);
      if (!mounted) return;
      if (saved) {
        done++;
        setState(() => _removeGroupLocally(id));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy.removeAll(ids);
      _selectedIds.clear();
      _selectMode = false;
    });
    _snack(done > 0 ? 'admin_report_dismissed' : 'admin_report_action_failed');
    if (done > 0) await AdminAuditLog.log('bulk dismiss', '$done items');
  }

  // ---- messages tab actions (simple spinner, no optimistic map) ----

  void _updatePostLocally(String postId, String message) {
    _posts = _posts
        .map((p) => p.id == postId ? p.copyWith(message: message) : p)
        .toList();
    for (final g in _groups) {
      if (g.targetId == postId) g.message = message;
    }
  }

  void _updateReplyLocally(String replyId, String message) {
    _posts = _posts
        .map((p) => p.copyWith(
              replies: p.replies
                  .map((r) =>
                      r.id == replyId ? r.copyWith(message: message) : r)
                  .toList(),
            ))
        .toList();
    for (final g in _groups) {
      if (g.targetId == replyId) g.message = message;
    }
  }

  Future<void> _editPost(ForumPost post) async {
    final next = await _editTextDialog(
      title: _adminText('admin_edit_title'),
      initial: post.message,
    );
    if (next == null || next.isEmpty || !mounted) return;
    if (next == post.message) return;
    setState(() => _busy.add(post.id));
    final ok =
        await _forumRepo.adminUpdatePost(postId: post.id, message: next);
    if (!mounted) return;
    setState(() {
      _busy.remove(post.id);
      if (ok) _updatePostLocally(post.id, next);
    });
    _snack(ok ? 'admin_saved' : 'admin_report_action_failed');
    if (ok) await AdminAuditLog.log('edit post', next);
  }

  Future<void> _deletePost(ForumPost post) async {
    final ok = await _confirm(
      titleKey: 'admin_delete_confirm_title',
      bodyKey: 'admin_delete_confirm_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(post.id));
    final saved = await _forumRepo.adminDeleteTarget(
      targetId: post.id,
      targetKind: 'post',
    );
    if (!mounted) return;
    setState(() {
      _busy.remove(post.id);
      if (saved) {
        _posts.removeWhere((p) => p.id == post.id);
        _groups.removeWhere((g) => g.targetId == post.id);
      }
    });
    _snack(saved ? 'admin_report_deleted' : 'admin_report_action_failed');
    if (saved) await AdminAuditLog.log('delete post', post.message);
  }

  Future<void> _editReply(String postId, ForumReply reply) async {
    final next = await _editTextDialog(
      title: _adminText('admin_edit_title'),
      initial: reply.message,
    );
    if (next == null || next.isEmpty || !mounted) return;
    if (next == reply.message) return;
    setState(() => _busy.add(reply.id));
    final ok = await _forumRepo.adminUpdateReply(
      postId: postId,
      replyId: reply.id,
      message: next,
    );
    if (!mounted) return;
    setState(() {
      _busy.remove(reply.id);
      if (ok) _updateReplyLocally(reply.id, next);
    });
    _snack(ok ? 'admin_saved' : 'admin_report_action_failed');
    if (ok) await AdminAuditLog.log('edit reply', next);
  }

  Future<void> _deleteReply(String postId, ForumReply reply) async {
    final ok = await _confirm(
      titleKey: 'admin_delete_confirm_title',
      bodyKey: 'admin_delete_confirm_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(reply.id));
    final saved = await _forumRepo.adminDeleteTarget(
      targetId: reply.id,
      targetKind: 'reply',
      parentPostId: postId,
    );
    if (!mounted) return;
    setState(() {
      _busy.remove(reply.id);
      if (saved) _removeGroupLocally(reply.id);
    });
    _snack(saved ? 'admin_report_deleted' : 'admin_report_action_failed');
    if (saved) await AdminAuditLog.log('delete reply', reply.message);
  }

  // ---- visitors tab actions ----

  Future<void> _editVisitor(AdminVisitor v) async {
    final nameCtrl = TextEditingController(text: v.name);
    final addrCtrl = TextEditingController(text: v.address);
    String? error;
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(_adminText('admin_visitor_edit')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _adminText('admin_visitor_name'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addrCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _adminText('admin_visitor_address'),
                    errorText: switch (error) {
                      null => null,
                      final key => _adminText(key),
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_adminText('admin_pin_cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  final key =
                      VisitorRepository.validateAddress(addrCtrl.text);
                  if (nameCtrl.text.trim().isEmpty || key != null) {
                    setDialog(() => error = key ?? 'visitor_required');
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmDark,
                  foregroundColor: Colors.white,
                ),
                child: Text(_adminText('admin_save')),
              ),
            ],
          ),
        ),
      );
      if (saved != true || !mounted) return;
      setState(() => _busy.add(v.id));
      final ok = await _visitorRepo.updateVisitor(
        id: v.id,
        name: nameCtrl.text,
        address: addrCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _busy.remove(v.id);
        if (ok) {
          final i = _visitors.indexWhere((e) => e.id == v.id);
          if (i != -1) {
            _visitors[i] = AdminVisitor(
              id: v.id,
              name: nameCtrl.text.trim(),
              address: addrCtrl.text.trim(),
              lang: v.lang,
              createdAt: v.createdAt,
            );
          }
        }
      });
      _snack(ok ? 'admin_saved' : 'admin_report_action_failed');
      if (ok) await AdminAuditLog.log('edit visitor', nameCtrl.text.trim());
    } finally {
      nameCtrl.dispose();
      addrCtrl.dispose();
    }
  }

  Future<void> _deleteVisitor(AdminVisitor v) async {
    final ok = await _confirm(
      titleKey: 'admin_visitor_delete_title',
      bodyKey: 'admin_visitor_delete_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(v.id));
    final saved = await _visitorRepo.deleteVisitor(v.id);
    if (!mounted) return;
    setState(() {
      _busy.remove(v.id);
      if (saved) _visitors.removeWhere((e) => e.id == v.id);
    });
    _snack(saved ? 'admin_visitor_deleted' : 'admin_report_action_failed');
    if (saved) await AdminAuditLog.log('delete visitor', v.name);
  }

  // ---- private tab actions (in-place) ----

  Future<void> _editCandle(AdminCandleMessage c) async {
    final next = await _editTextDialog(
      title: _adminText('admin_edit_title'),
      initial: c.message,
      maxLength: 500,
    );
    if (next == null || next.isEmpty || !mounted) return;
    setState(() => _busy.add(c.id));
    final ok = await _candleRepo.updateMessage(id: c.id, message: next);
    if (!mounted) return;
    setState(() {
      _busy.remove(c.id);
      if (ok) {
        final i = _candle.indexWhere((e) => e.id == c.id);
        if (i != -1) {
          _candle[i] = AdminCandleMessage(
            id: c.id,
            name: c.name,
            message: next,
            createdAt: c.createdAt,
          );
        }
      }
    });
    _snack(ok ? 'admin_saved' : 'admin_report_action_failed');
    if (ok) await AdminAuditLog.log('edit private', next);
  }

  Future<void> _deleteCandle(AdminCandleMessage c) async {
    final ok = await _confirm(
      titleKey: 'admin_delete_confirm_title',
      bodyKey: 'admin_delete_confirm_body',
      confirmKey: 'admin_confirm_delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(c.id));
    final saved = await _candleRepo.deleteMessage(c.id);
    if (!mounted) return;
    setState(() {
      _busy.remove(c.id);
      if (saved) _candle.removeWhere((e) => e.id == c.id);
    });
    _snack(saved ? 'admin_report_deleted' : 'admin_report_action_failed');
    if (saved) await AdminAuditLog.log('delete private', c.name);
  }

  Future<void> _exportVisitors() async {
    final rows = <List<String>>[
      ['name', 'address', 'lang', 'created_at'],
      for (final v in _rangeFilteredVisitors)
        [v.name, v.address, v.lang, v.createdAt.toIso8601String()],
    ];
    await Clipboard.setData(
        ClipboardData(text: AdminAuditLog.toCsv(rows)));
    if (!mounted) return;
    _snack('admin_saved');
    await AdminAuditLog.log('export visitors', '${rows.length - 1} rows');
  }

  Future<void> _exportPrivate() async {
    final rows = <List<String>>[
      ['name', 'message', 'created_at'],
      for (final c in _rangeFilteredCandle)
        [c.name, c.message, c.createdAt.toIso8601String()],
    ];
    await Clipboard.setData(
        ClipboardData(text: AdminAuditLog.toCsv(rows)));
    if (!mounted) return;
    _snack('admin_saved');
    await AdminAuditLog.log('export private', '${rows.length - 1} rows');
  }

  Future<void> _openAuditHistory() async {
    final items = await AdminAuditLog.fetch();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('History'),
        content: SizedBox(
          width: 400,
          child: items.isEmpty
              ? const Text('No actions yet.')
              : SizedBox(
                  height: 320,
                  width: 400,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return ListTile(
                        dense: true,
                        title: Text(e['action'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${e['detail'] ?? ''}\n${e['at'] ?? ''}',
                            style:
                                const TextStyle(fontSize: 11.5)),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AdminAuditLog.clear();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---- filtering (per-tab queries) ----

  String _q(int tab) => _tabQueries[tab].trim().toLowerCase();

  List<_ReportedGroup> get _filteredGroups {
    final q = _q(0);
    if (q.isEmpty) return _groups;
    return _groups.where((g) {
      if ((g.authorName ?? '').toLowerCase().contains(q)) return true;
      if ((g.message ?? '').toLowerCase().contains(q)) return true;
      return g.reports.any((r) =>
          r.reporterName.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q) ||
          r.details.toLowerCase().contains(q));
    }).toList();
  }

  /// Maps a stored report reason to one of the four known codes so the
  /// "Other" filter also catches empty/unknown reasons, matching the
  /// label shown on the report card.
  static String _reportReasonCode(String reason) => switch (reason) {
        'profanity' => 'profanity',
        'inappropriate' => 'inappropriate',
        'spam' => 'spam',
        _ => 'other',
      };

  /// The search-filtered report groups with the reason filter applied on
  /// top. Index 0 returns the search result unchanged, so nothing
  /// behaves differently until the family taps a reason pill.
  List<_ReportedGroup> get _reasonFilteredGroups {
    final base = _filteredGroups;
    if (_reportReason == 0) return base;
    final code = switch (_reportReason) {
      1 => 'profanity',
      2 => 'inappropriate',
      3 => 'spam',
      _ => 'other',
    };
    return base
        .where(
          (g) => g.reports.any((r) => _reportReasonCode(r.reason) == code),
        )
        .toList();
  }

  List<ForumPost> get _filteredPosts {
    final q = _q(1);
    if (q.isEmpty) return _posts;
    return _posts.where((p) {
      if (p.authorName.toLowerCase().contains(q)) return true;
      if (p.message.toLowerCase().contains(q)) return true;
      return p.replies.any((r) =>
          r.authorName.toLowerCase().contains(q) ||
          r.message.toLowerCase().contains(q));
    }).toList();
  }

  List<AdminVisitor> get _filteredVisitors {
    final q = _q(2);
    if (q.isEmpty) return _visitors;
    return _visitors.where((v) {
      return v.name.toLowerCase().contains(q) ||
          v.address.toLowerCase().contains(q);
    }).toList();
  }

  /// Search-filtered messages with the Messages quick pill on top.
  /// Matches when the post itself or any reply falls in the range.
  List<ForumPost> get _rangeFilteredPosts {
    if (!_messageDates.isActive) return _filteredPosts;
    return _filteredPosts.where((p) {
      if (_messageDates.matches(p.createdAt)) return true;
      return p.replies.any((r) => _messageDates.matches(r.createdAt));
    }).toList();
  }

  /// Shared "clear search + reset date pill" — only clears the current tab.
  void _clearTabFilters(_DatePillFilter dates) {
    setState(() {
      dates.reset();
      _tabQueries[_tab] = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String v) {
    setState(() => _tabQueries[_tab] = v);
  }

  void _onTabSelected(int i) {
    setState(() {
      _tab = i;
      _selectMode = false;
      _selectedIds.clear();
      // Restore this tab's own query in the shared box.
      _searchController.text = _tabQueries[i];
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });
  }

  /// Paged slice for "Load more" pagination.
  List<T> _page<T>(List<T> all, int tab) {
    final n = _visibleCount[tab].clamp(1, all.length + 30);
    if (all.length <= n) return all;
    return all.sublist(0, n);
  }

  Widget _loadMoreButton(int tab, int total) {
    if (total <= _visibleCount[tab]) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: OutlinedButton(
          onPressed: () =>
              setState(() => _visibleCount[tab] = _visibleCount[tab] + 30),
          child: Text('Load more (${total - _visibleCount[tab]} left)'),
        ),
      ),
    );
  }

  /// Search-filtered visitors with the Visitors tab's date pill on top.
  List<AdminVisitor> get _rangeFilteredVisitors {
    if (!_visitorDates.isActive) return _filteredVisitors;
    return _filteredVisitors
        .where((v) => _visitorDates.matches(v.createdAt))
        .toList();
  }

  /// Search-filtered candles with the Private tab's date pill on top.
  List<AdminCandleMessage> get _rangeFilteredCandle {
    if (!_privateDates.isActive) return _filteredCandle;
    return _filteredCandle
        .where((c) => _privateDates.matches(c.createdAt))
        .toList();
  }

  /// Language tag for a visitor row, or null when the stored code is
  /// empty/unknown (older rows) so no chip is shown.
  String? _visitorLangLabel(LanguageProvider lang, String code) {
    return switch (code.trim().toLowerCase()) {
      'en' => _adminText('admin_lang_en'),
      'tl' => _adminText('admin_lang_tl'),
      'bi' => _adminText('admin_lang_bi'),
      _ => null,
    };
  }

  List<AdminCandleMessage> get _filteredCandle {
    final q = _q(3);
    if (q.isEmpty) return _candle;
    return _candle.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.message.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tabs = [
      _adminText('admin_tab_reports'),
      _adminText('admin_tab_messages'),
      _adminText('admin_tab_visitors'),
      _adminText('admin_tab_private'),
    ];
    final counts = [
      _groups.length,
      _posts.length,
      _visitors.length,
      _candle.length,
    ];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _AdminHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                  onPinSettings: _openChangePin,
                  onHistory: _openAuditHistory,
                ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _SegmentedTabs(
                tabs: tabs,
                counts: counts,
                selected: _tab,
                onSelect: _onTabSelected,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _AdminSearch(
                controller: _searchController,
                hint: _adminText('admin_search_hint'),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildTabBody(lang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(LanguageProvider lang) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.gold,
        ),
      );
    }
    if (_loadError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_adminText('admin_reports_load_failed')),
            if (_loadErrorDetail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _loadErrorDetail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_adminText('forum_retry')),
            ),
          ],
        ),
      );
    }
    return switch (_tab) {
      0 => _buildReportsList(lang),
      1 => _buildMessagesList(lang),
      2 => _buildVisitorsList(lang),
      _ => _buildPrivateList(lang),
    };
  }

  Widget _buildReportsList(LanguageProvider lang) {
    final groups = _reasonFilteredGroups;
    final page = _page(groups, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportReasonChips(
          selected: _reportReason,
          labels: [
            _adminText('admin_filter_all'),
            _adminText('forum_report_reason_profanity'),
            _adminText('forum_report_reason_inappropriate'),
            _adminText('forum_report_reason_spam'),
            _adminText('forum_report_reason_other'),
          ],
          onSelect: (i) => setState(() => _reportReason = i),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: groups.isEmpty
                  ? null
                  : () => setState(() {
                        _selectMode = !_selectMode;
                        _selectedIds.clear();
                      }),
              child: Text(_selectMode ? 'Done' : 'Select'),
            ),
            const Spacer(),
            if (_selectMode)
              Text('${_selectedIds.length} selected',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        if (_selectMode && _selectedIds.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _bulkDismissSelected,
                  child: const Text('Dismiss all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _bulkDeleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roseDeep,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    _query.trim().isNotEmpty || _reportReason != 0
                        ? 'No matches. Try Reset.'
                        : _adminText('admin_reports_empty'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.warmDark,
                  child: ListView.separated(
                    itemCount: page.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.length) {
                        return _loadMoreButton(0, groups.length);
                      }
                      final g = page[i];
                      final selected = _selectedIds.contains(g.targetId);
                      return GestureDetector(
                        onLongPress: () => setState(() {
                          _selectMode = true;
                          _selectedIds.add(g.targetId);
                        }),
                        child: Stack(
                          children: [
                            _ReportCard(
                              group: g,
                              busy: _busy.contains(g.targetId),
                              reasonLabel: (code) =>
                                  _reasonLabel(lang, code),
                              onDelete: () => _confirmDeleteGroup(g),
                              onDismiss: () => _confirmDismissGroup(g),
                            ),
                            if (_selectMode)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Checkbox(
                                  value: selected,
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selectedIds.add(g.targetId);
                                    } else {
                                      _selectedIds.remove(g.targetId);
                                    }
                                  }),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Shared pill filter card for the Messages, Visitors, and Private tabs.
  /// Each tab passes its own [_DatePillFilter] plus its counts.
  Widget _dateCard({
    required _DatePillFilter dates,
    required int shown,
    required int total,
    required String unit,
  }) {
    final q = _query.trim().isNotEmpty;
    return _DatePillFilterCard(
      pill: dates.pill,
      rangeLabel: dates.label,
      expanded: dates.expanded,
      shown: shown,
      total: total,
      unit: unit,
      filtered: dates.isActive || q,
      onToggle: () => setState(() => dates.expanded = !dates.expanded),
      onSelect: (p) => setState(() => dates.select(p)),
      onClear: () => _clearTabFilters(dates),
      weekYear: dates.weekYear,
      weekMonth: dates.weekMonth,
      weekWeek: dates.weekWeek,
      onPickWeek: (y, m, w) => setState(() => dates.pickWeek(y, m, w)),
      monthYear: dates.monthYear,
      monthMonth: dates.monthMonth,
      onPickMonth: (y, m) => setState(() => dates.pickMonth(y, m)),
    );
  }

  /// Shared "no rows" state with a reset button when a search or date
  /// pill is hiding everything.
  Widget _emptyWithReset(String textKey, _DatePillFilter dates) {
    final filtered = dates.isActive || _query.trim().isNotEmpty;
    final isOffline =
        !SupabaseConfig.isConfigured || _loadErrorDetail.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_adminText(textKey)),
          if (isOffline) ...[
            const SizedBox(height: 6),
            const Text(
              'Offline or no permission — pull to retry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          if (filtered) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _clearTabFilters(dates),
              child: const Text('Reset filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesList(LanguageProvider lang) {
    final posts = _rangeFilteredPosts;
    final page = _page(posts, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateCard(
          dates: _messageDates,
          shown: posts.length,
          total: _posts.length,
          unit: 'messages',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: posts.isEmpty
              ? _emptyWithReset('admin_messages_empty', _messageDates)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.warmDark,
                  child: ListView.separated(
                    itemCount: page.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.length) {
                        return _loadMoreButton(1, posts.length);
                      }
                      final post = page[i];
                      final busy = _busy.contains(post.id);
                      return _AdminMessageCard(
                        title: post.authorName,
                        message: post.message,
                        date: _adminDateTime(post.createdAt),
                        badge: _adminText('admin_reports_post'),
                        busy: busy,
                        onEdit: () => _editPost(post),
                        onDelete: () => _deletePost(post),
                        repliesLabel: _adminText('admin_replies_label'),
                        replyTiles: [
                          for (final r in post.replies)
                            _AdminReplyTile(
                              name: r.authorName,
                              message: r.message,
                              date: _adminDateTime(r.createdAt),
                              busy: _busy.contains(r.id),
                              onEdit: () => _editReply(post.id, r),
                              onDelete: () => _deleteReply(post.id, r),
                            ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVisitorsList(LanguageProvider lang) {
    final visitors = _rangeFilteredVisitors;
    final page = _page(visitors, 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateCard(
          dates: _visitorDates,
          shown: visitors.length,
          total: _visitors.length,
          unit: 'visitors',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: visitors.isEmpty ? null : _exportVisitors,
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copy CSV'),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: visitors.isEmpty
              ? _emptyWithReset('admin_visitors_empty', _visitorDates)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.warmDark,
                  child: ListView.separated(
                    itemCount: page.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.length) {
                        return _loadMoreButton(2, visitors.length);
                      }
                      final v = page[i];
                      final busy = _busy.contains(v.id);
                      return _PlainAdminCard(
                        badge: _adminText('admin_tab_visitors'),
                        date: _adminDateTime(v.createdAt),
                        title: v.name.isEmpty ? 'Anonymous' : v.name,
                        message: v.address,
                        busy: busy,
                        onEdit: () => _editVisitor(v),
                        onDelete: () => _deleteVisitor(v),
                        showAsAddress: true,
                        langLabel: _visitorLangLabel(lang, v.lang),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPrivateList(LanguageProvider lang) {
    final items = _rangeFilteredCandle;
    final page = _page(items, 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateCard(
          dates: _privateDates,
          shown: items.length,
          total: _candle.length,
          unit: 'messages',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: items.isEmpty ? null : _exportPrivate,
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copy CSV'),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty
              ? _emptyWithReset('admin_private_empty', _privateDates)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.warmDark,
                  child: ListView.separated(
                    itemCount: page.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.length) {
                        return _loadMoreButton(3, items.length);
                      }
                      final c = page[i];
                      final busy = _busy.contains(c.id);
                      return _PlainAdminCard(
                        badge: _adminText('admin_tab_private'),
                        date: _adminDateTime(c.createdAt),
                        title: c.name.isEmpty ? 'Anonymous' : c.name,
                        message: c.message,
                        busy: busy,
                        onEdit: () => _editCandle(c),
                        onDelete: () => _deleteCandle(c),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Real page header: transparent, roomy back + title + divider.
class _AdminHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPinSettings;
  final VoidCallback onHistory;

  const _AdminHeader({
    required this.onBack,
    required this.onPinSettings,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adminText('admin_reports_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _adminText('admin_reports_subtitle'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'History',
                  child: _CircleIconButton(
                    icon: Icons.history_rounded,
                    onTap: onHistory,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _adminText('admin_change_pin'),
                  child: _CircleIconButton(
                    icon: Icons.lock_outline_rounded,
                    onTap: onPinSettings,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Divider(height: 1, color: AppColors.stoneBorder),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mistPaper,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.warmDeep,
          ),
        ),
      ),
    );
  }
}

/// Segmented pill tab bar: mist container, white selected pill,
/// each tab with a small count badge (hidden when the count is 0).
class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SegmentedTabs({
    required this.tabs,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected == i ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected == i
                              ? AppColors.stoneBorder.withValues(alpha: 0.6)
                              : Colors.transparent,
                        ),
                        boxShadow: selected == i
                            ? [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: selected == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected == i
                              ? AppColors.textDark
                              : AppColors.muted,
                        ),
                      ),
                    ),
                    if (i < counts.length && counts[i] > 0)
                      Positioned(
                        top: -7,
                        right: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.roseDeep,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            counts[i] > 99 ? '99+' : '${counts[i]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded search field.
class _AdminSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _AdminSearch({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: AppColors.muted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Avatar circle with initials.
class _AdminAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _AdminAvatar({required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _adminAvatarColor(name),
      ),
      child: Center(
        child: Text(
          _adminInitials(name),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.warmDeep,
          ),
        ),
      ),
    );
  }
}

/// Bottom action row: quiet left button + filled delete right button.
class _AdminActionRow extends StatelessWidget {
  final IconData leftIcon;
  final String leftLabel;
  final VoidCallback? onLeft;
  final String rightLabel;
  final VoidCallback? onRight;
  final bool busy;

  const _AdminActionRow({
    required this.leftIcon,
    required this.leftLabel,
    required this.onLeft,
    required this.rightLabel,
    required this.onRight,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextButton.icon(
              onPressed: busy ? null : onLeft,
              icon: Icon(leftIcon, size: 15),
              label: Text(
                leftLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warmDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onRight,
              icon: busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 15),
              label: Text(
                rightLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Base white card shared by every admin list.
class _AdminCard extends StatelessWidget {
  final Widget child;

  const _AdminCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: child,
      ),
    );
  }
}

/// Small muted chip (kind, date).
class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.warmDeep,
        ),
      ),
    );
  }
}

/// Report card: avatar row, message, reason chips, reporters, actions.
class _ReportCard extends StatelessWidget {
  final _ReportedGroup group;
  final bool busy;
  final String Function(String code) reasonLabel;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.group,
    required this.busy,
    required this.reasonLabel,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final missing = group.message == null;
    final name = (group.authorName ?? '').isEmpty
        ? 'Anonymous'
        : group.authorName!;
    final reasons = group.reports
        .map((r) => reasonLabel(r.reason.isEmpty ? 'other' : r.reason))
        .toSet()
        .toList();
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.messageAt == null
                          ? _adminDate(group.latest)
                          : _adminDateTime(group.messageAt!),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _MetaChip(
                label: '${group.reports.length} report${group.reports.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reason in reasons)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (missing)
            Text(
              _adminText('admin_reports_deleted_target'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            )
          else
            Text(
              group.message ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          for (final r in group.reports)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${r.reporterName} · ${_adminDate(r.createdAt)}${r.details.isNotEmpty ? ' — ${r.details}' : ''}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.check_rounded,
            leftLabel: _adminText('admin_report_dismiss'),
            onLeft: onDismiss,
            rightLabel: _adminText('admin_report_delete'),
            onRight: missing ? null : onDelete,
            busy: busy,
          ),
        ],
      ),
    );
  }
}

/// Message card for the Messages and Private tabs.
class _AdminMessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final String badge;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String repliesLabel;
  final List<Widget> replyTiles;

  const _AdminMessageCard({
    required this.title,
    required this.message,
    required this.date,
    required this.badge,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.repliesLabel,
    required this.replyTiles,
  });

  @override
  Widget build(BuildContext context) {
    final name = title.isEmpty ? 'Anonymous' : title;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$badge · $date',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.edit_outlined,
            leftLabel: _adminText('admin_report_edit'),
            onLeft: onEdit,
            rightLabel: _adminText('admin_report_delete'),
            onRight: onDelete,
            busy: busy,
          ),
          if (replyTiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${repliesLabel.isEmpty ? 'Replies' : repliesLabel} (${replyTiles.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            ...replyTiles,
          ],
        ],
      ),
    );
  }
}

class _AdminReplyTile extends StatelessWidget {
  final String name;
  final String message;
  final String date;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminReplyTile({
    required this.name,
    required this.message,
    required this.date,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final display = name.isEmpty ? 'Anonymous' : name;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: display, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallAdminButton(
                  icon: Icons.edit_outlined,
                  onTap: busy ? null : onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAdminButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.roseDeep,
                  onTap: busy ? null : onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plain avatar + text card for Visitors and Private tabs.
/// When [showAsAddress] is true (visitors roster), the body renders as a
/// small muted location row instead of message-style text.
class _PlainAdminCard extends StatelessWidget {
  final String badge;
  final String date;
  final String title;
  final String message;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showAsAddress;

  /// Optional language chip for the Visitors tab (English/Tagalog/Bicol).
  /// Null on every other caller, so those cards stay exactly as before.
  final String? langLabel;

  const _PlainAdminCard({
    required this.badge,
    required this.date,
    required this.title,
    required this.message,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    this.showAsAddress = false,
    this.langLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name = title.isEmpty ? 'Anonymous' : title;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$badge · $date',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (langLabel != null) ...[
                const SizedBox(width: 8),
                _MetaChip(label: langLabel!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (showAsAddress)
            if (message.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink()
          else
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.edit_outlined,
            leftLabel: showAsAddress
                ? _adminText('admin_visitor_edit')
                : _adminText('admin_report_edit'),
            onLeft: onEdit,
            rightLabel: showAsAddress
                ? _adminText('admin_visitor_delete')
                : _adminText('admin_report_delete'),
            onRight: onDelete,
            busy: busy,
          ),
        ],
      ),
    );
  }
}

class _SmallAdminButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallAdminButton({
    required this.icon,
    this.color = AppColors.textDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: AppColors.stoneBorder.withValues(alpha: 0.8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 15),
      ),
    );
  }
}

/// Reason pills for the Reports tab: All / curse words / inappropriate /
/// spam / other. Horizontally scrollable because the labels vary in
/// length. Additive UI — the other admin tabs keep their own layout.
class _ReportReasonChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ReportReasonChips({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected == i
                          ? AppColors.stoneBorder.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == i
                          ? AppColors.textDark
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
