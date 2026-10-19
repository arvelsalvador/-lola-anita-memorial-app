import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/data/admin/admin_audit_log.dart';
import 'package:nita/data/condolences/condolence_repository.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/data/security/admin_pin.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/admin_candle_message_model.dart';
import 'package:nita/models/admin_report_model.dart';
import 'package:nita/models/admin_visitor_model.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/widgets/circle_icon_button.dart';

part 'admin_dialogs.dart';
part 'admin_filters.dart';
part 'admin_widgets.dart';
part 'admin_date_filters.dart';

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
    final client = SupabaseConfig.safeClient();
    if (client == null) return;
    try {
      final channel = client.channel('admin-reports-feed');
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
      final client = SupabaseConfig.safeClient();
      if (client != null) {
        await client.removeChannel(channel);
      }
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

