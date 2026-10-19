import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/forum/forum_repository.dart';
import 'package:nita/data/forum/spam_guard.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/views/condolences/forum/edit_text_sheet.dart';
import 'package:nita/views/condolences/forum/likers_sheet.dart';
import 'package:nita/views/condolences/forum/report_sheet.dart';

/// Minimal flat message card (Image 1 port, warm-adapted):
/// paper card, flat avatars, text-only actions, divider, flat replies,
/// pill composer. Inter + memorial tokens kept — no blue.
class ForumPostCard extends StatefulWidget {
  final ForumPost post;
  final void Function(String reactionType) onReactionTap;
  final void Function(String replyId, String reactionType) onReplyReactionTap;
  final Future<ForumReply?> Function(
    String authorName,
    String message,
    String replyToName,
  ) onSendReply;
  /// Loads liker display names for a post id or reply id.
  final Future<List<String>> Function(String targetId) onViewLikers;
  /// True when the post was already reported by this device.
  final bool isPostReported;
  /// True when the given reply id was already reported by this device.
  final bool Function(String replyId) isReplyReported;
  /// Persists a moderation report. Returns saved / alreadyReported / failed
  /// so the UI can show thanks / already / retry respectively.
  final Future<ReportSubmitOutcome> Function(
    String targetId,
    String targetKind,
    String reason,
    String details,
  ) onSubmitReport;
  /// True when the post was created on this device (fix #4: shows
  /// Edit/Delete instead of Report in the post menu).
  final bool isPostOwn;
  /// True when your own post is still inside the edit window.
  final bool canEditPost;
  /// True when the given reply id was created on this device.
  final bool Function(String replyId) isReplyOwn;
  /// True when your own reply is still inside the edit window.
  final bool Function(String replyId) canEditReply;
  /// Saves an edited post message. Returns true when saved.
  final Future<bool> Function(String message) onEditPost;
  /// Deletes your own post. Returns true when deleted.
  final Future<bool> Function() onDeletePost;
  /// Saves an edited reply message. Returns true when saved.
  final Future<bool> Function(String replyId, String message) onEditReply;
  /// Deletes your own reply. Returns true when deleted.
  final Future<bool> Function(String replyId) onDeleteReply;
  /// Re-uploads an unsent (pendingSync) post. Best-effort.
  final VoidCallback onRetrySend;
  /// Re-uploads an unsent (pendingSync) reply. Best-effort.
  final void Function(String replyId) onRetryReplySend;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.onReactionTap,
    required this.onReplyReactionTap,
    required this.onSendReply,
    required this.onViewLikers,
    this.isPostReported = false,
    this.isReplyReported = _notReported,
    this.onSubmitReport = _noReport,
    this.isPostOwn = false,
    this.canEditPost = false,
    this.isReplyOwn = _notOwn,
    this.canEditReply = _cannotEdit,
    this.onEditPost = _noEdit,
    this.onDeletePost = _noDelete,
    this.onEditReply = _noReplyEdit,
    this.onDeleteReply = _noReplyDelete,
    this.onRetrySend = _noRetrySend,
    this.onRetryReplySend = _noRetryReplySend,
  });

  static void _noRetrySend() {}
  static void _noRetryReplySend(String _) {}

  static bool _notReported(String _) => false;
  static bool _notOwn(String _) => false;
  static bool _cannotEdit(String _) => false;
  static Future<ReportSubmitOutcome> _noReport(
    String a,
    String b,
    String c,
    String d,
  ) async =>
      ReportSubmitOutcome.failed;
  static Future<bool> _noEdit(String _) async => false;
  static Future<bool> _noDelete() async => false;
  static Future<bool> _noReplyEdit(String _, String _) async => false;
  static Future<bool> _noReplyDelete(String _) async => false;

  @override
  State<ForumPostCard> createState() => _ForumPostCardState();
}

class _ForumPostCardState extends State<ForumPostCard> {
  String? _replyTarget;
  bool _repliesExpanded = false;
  // Hidden by default — only an explicit Reply tap opens the textfield.
  bool _composerOpen = false;

  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final GlobalKey _composerKey = GlobalKey();
  final VisitorRepository _visitorRepo = const VisitorRepository();
  String _visitorName = '';
  bool _sending = false;
  // Relative timestamps ("3 hours ago") are computed from DateTime.now()
  // at build time — a slow 60s tick keeps them honest. Bounded cost: one
  // timer per visible card, one setState per minute.
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadVisitorName();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    // Desktop/web: plain Enter sends, Shift+Enter inserts a newline.
    _composerFocus.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (event.logicalKey != LogicalKeyboardKey.enter) {
        return KeyEventResult.ignored;
      }
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored; // let Shift+Enter make a newline
      }
      _handleSend();
      return KeyEventResult.handled;
    };
  }

  Future<void> _loadVisitorName() async {
    try {
      final name = await _visitorRepo.localName();
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() => _visitorName = name.trim());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  /// Removes a leading @mention, matching full names like
  /// "@Juan Dela Cruz". First tries the exact current target, then falls
  /// back to "@ + up to 3 words" so switching targets never leaves
  /// "Dela Cruz ..." behind.
  String _stripLeadingMention(String text) {
    if (!text.startsWith('@')) return text;
    final oldTarget = (_replyTarget ?? '').trim();
    if (oldTarget.isNotEmpty && text.startsWith('@$oldTarget')) {
      return text.substring('@$oldTarget'.length).trimLeft();
    }
    final m = RegExp(r'^@\S+(?:\s+\S+){0,2}\s*').firstMatch(text);
    if (m == null) return text;
    return text.substring(m.end);
  }

  void _targetReply(String authorName) {
    final name = authorName.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact().catchError((_) {});
    // Re-read the gate name: the card may have been built before the
    // splash gate saved it, so the cached copy can be stale/empty.
    _loadVisitorName();
    final current = _composerController.text;
    final stripped = _stripLeadingMention(current);
    setState(() {
      _replyTarget = name;
      _repliesExpanded = true;
      _composerOpen = true;
      _composerController.text = stripped;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _composerFocus.requestFocus();
    });
  }

  void _toggleRepliesThread() {
    HapticFeedback.lightImpact().catchError((_) {});
    // Same stale-name guard as _targetReply.
    if (_visitorName.isEmpty) _loadVisitorName();
    final expanding = !_repliesExpanded;
    final current = _composerController.text;
    final stripped = _stripLeadingMention(current);
    setState(() {
      _repliesExpanded = expanding;
      if (expanding) {
        _composerOpen = true;
        _replyTarget = null;
        _composerController.text = stripped;
        _composerController.selection = TextSelection.fromPosition(
          TextPosition(offset: _composerController.text.length),
        );
      } else {
        _composerOpen = false;
        _replyTarget = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (expanding) {
        _composerFocus.requestFocus();
      } else {
        _composerFocus.unfocus();
      }
    });
  }

  /// Expands the thread for reading only — no composer, no keyboard.
  /// Used by the preview's "show all" button so visitors can read
  /// without being forced to reply.
  void _expandThreadOnly() {
    if (_repliesExpanded) return;
    HapticFeedback.lightImpact().catchError((_) {});
    setState(() => _repliesExpanded = true);
  }

  void _clearTarget() {
    HapticFeedback.lightImpact().catchError((_) {});
    final current = _composerController.text;
    final stripped = _stripLeadingMention(current);
    setState(() {
      _replyTarget = null;
      _composerController.text = stripped;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
    });
  }

  Future<void> _openReport({
    required String targetId,
    required String targetKind,
    required bool alreadyReported,
  }) async {
    HapticFeedback.lightImpact().catchError((_) {});
    if (!mounted) return;
    if (alreadyReported) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_report_already'))),
      );
      return;
    }
    // Temp ids don't exist on the server yet — reporting them always
    // fails, so stop here instead of opening the sheet then failing.
    if (targetId.startsWith('msg-') || targetId.startsWith('reply-')) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_report_failed'))),
      );
      return;
    }
    final outcome = await ReportSheet.show(
      context,
      targetId: targetId,
      targetKind: targetKind,
      alreadyReported: alreadyReported,
      onSubmit: (reason, details) => widget.onSubmitReport(
        targetId,
        targetKind,
        reason,
        details,
      ),
    );
    if (!mounted || outcome == null) return;
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.t(
          switch (outcome) {
            ReportSubmitOutcome.saved => 'forum_report_thanks',
            ReportSubmitOutcome.alreadyReported => 'forum_report_already',
            ReportSubmitOutcome.failed => 'forum_report_failed',
          },
        )),
      ),
    );
  }

  /// Opens the edit sheet for your own post text (fix #4).
  Future<void> _openEditPost() async {
    HapticFeedback.lightImpact().catchError((_) {});
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    await EditTextSheet.show(
      context,
      title: lang.t('forum_edit'),
      initialText: widget.post.message,
      onSave: (message) => widget.onEditPost(message),
    );
  }

  /// Opens the edit sheet for your own reply text (fix #4).
  Future<void> _openEditReply(ForumReply reply) async {
    HapticFeedback.lightImpact().catchError((_) {});
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    await EditTextSheet.show(
      context,
      title: lang.t('forum_edit'),
      initialText: reply.message,
      onSave: (message) => widget.onEditReply(reply.id, message),
    );
  }

  /// Confirms then deletes your own post or reply (fix #4).
  /// Returns silently when the delete fails (controller reverts).
  Future<void> _confirmDelete({
    required bool isReply,
    required String replyId,
  }) async {
    HapticFeedback.lightImpact().catchError((_) {});
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          lang.t('forum_delete'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          lang.t(isReply
              ? 'forum_delete_reply_confirm'
              : 'forum_delete_post_confirm'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(lang.t('forum_discard')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: _LikeRed.color,
            ),
            child: Text(lang.t('forum_delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = isReply
        ? await widget.onDeleteReply(replyId)
        : await widget.onDeletePost();
    // The controller restores the message when the database refuses the
    // delete (e.g. missing policy) — tell the user instead of silently
    // bringing it back.
    if (!ok && mounted) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_delete_failed'))),
      );
    }
  }

  Future<void> _handleSend() async {
    final body = _composerController.text.trim();
    if (body.isEmpty || _sending) return;
    if (body.length > 1000) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_send_failed'))),
      );
      return;
    }
    // Spam layer 2: blocklist before anything is sent or stored.
    if (SpamGuard.containsBlockedWords(body)) {
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_blocked_message'))),
      );
      return;
    }
    // Lock the send BEFORE the first await so a second quick tap (or
    // Enter) can't slip past the guard while the throttle check runs
    // and double-post.
    setState(() => _sending = true);
    HapticFeedback.lightImpact().catchError((_) {});
    try {
      // Spam layer 1: 1 reply per 20 seconds per device.
      final waitSeconds = await SpamGuard.secondsUntilNextReply();
      if (!mounted) return;
      if (waitSeconds > 0) {
        final lang = context.read<LanguageProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('forum_throttle_reply'))),
        );
        return;
      }
      var author = _visitorName;
      // Fresh identity check: this card may have cached an empty name
      // before the splash gate was completed (e.g. a brand-new browser
      // or incognito session). Re-read once before giving up to keep
      // the gate name — never silently post "Anonymous" when the name
      // exists on this device.
      if (author.isEmpty) {
        try {
          final fresh = await _visitorRepo.localName();
          author = (fresh ?? '').trim();
          if (mounted && author.isNotEmpty) {
            setState(() => _visitorName = author);
          }
        } catch (_) {}
      }
      final authorName = author.isEmpty ? 'Anonymous' : author;
      final target = (_replyTarget ?? '').trim();
      final startsWithMention =
          target.isNotEmpty && body.startsWith('@$target');
      final text =
          target.isNotEmpty && !startsWithMention ? '@$target $body' : body;
      final sent = await widget.onSendReply(authorName, text, target);
      if (!mounted) return;
      // Null = save failed: keep the typed text so nothing is lost.
      if (sent == null) {
        final lang = context.read<LanguageProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('forum_send_failed'))),
        );
        return;
      }
      _composerController.clear();
      await SpamGuard.recordReply();
      if (!mounted) return;
      setState(() {
        _replyTarget = null;
        _repliesExpanded = true;
        _composerOpen = false;
      });
      _composerFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('forum_send_failed'))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Relative first (<1h just now, <24h hours, <7d days), then exact.
  /// Uses existing keys forum_just_now / forum_hours_ago / forum_days_ago
  /// so EN/TL/BI all work. Future timestamps fall back to just now.
  String _formatRelative(
    LanguageProvider lang,
    DateTime dateTime, {
    required String fallback,
  }) {
    final now = DateTime.now();
    final diff = now.difference(dateTime.toLocal());
    if (diff.isNegative || diff.inMinutes < 60) {
      return lang.t('forum_just_now');
    }
    if (diff.inHours < 24) {
      return lang.t('forum_hours_ago', {'count': '${diff.inHours}'});
    }
    if (diff.inDays < 7) {
      return lang.t('forum_days_ago', {'count': '${diff.inDays}'});
    }
    return fallback;
  }

  /// Full date for the main post: "Kanina lamang" / "3 oras..." / "Okt 6, 2026".
  String _formatExact(BuildContext context, DateTime dateTime) {
    final lang = context.read<LanguageProvider>();
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsFil = [
      'Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun',
      'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis',
    ];
    final local = dateTime.toLocal();
    final month =
        (lang.isEnglish ? monthsEn : monthsFil)[local.month - 1];
    final fallback = '$month ${local.day}, ${local.year}';
    return _formatRelative(lang, dateTime, fallback: fallback);
  }

  /// Short date for replies: "Kanina lamang" / "Okt 7".
  String _formatShort(BuildContext context, DateTime dateTime) {
    final lang = context.read<LanguageProvider>();
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsFil = [
      'Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun',
      'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis',
    ];
    final local = dateTime.toLocal();
    final month =
        (lang.isEnglish ? monthsEn : monthsFil)[local.month - 1];
    final fallback = '$month ${local.day}';
    return _formatRelative(lang, dateTime, fallback: fallback);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final postedAt = _formatExact(context, post.createdAt);
    final lang = context.watch<LanguageProvider>();
    final liked = post.userReactions.contains('heart');
    final heartCount = post.reactions['heart'] ?? 0;
    final hasReplies = post.replies.isNotEmpty;
    final showThread = _repliesExpanded && hasReplies;
    // Fix #3: collapsed posts preview the newest 2 replies so threads
    // don't look empty. Full thread only when expanded.
    final showPreview = !_repliesExpanded && hasReplies;
    final showRepliesBlock = showThread || showPreview;
    // Fix #3: collapsed preview shows the FIRST 2 top-level replies
    // (oldest first), never reply-to-reply — nested @-replies without
    // their parent context are confusing out of order.
    final topLevelReplies = post.replies
        .where((r) => r.replyToName.trim().isEmpty)
        .toList();
    final previewBase =
        topLevelReplies.isNotEmpty ? topLevelReplies : post.replies;
    final visibleReplies = showThread
        ? post.replies
        : (previewBase.length <= 2
            ? previewBase
            : previewBase.sublist(0, 2));
    final previewRemaining = post.replies.length - visibleReplies.length;
    final showMoreButton = showPreview && previewRemaining > 0;
    final knownNames = <String>[
      post.authorName,
      ...post.replies.map((r) => r.authorName),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stoneBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name over clock-date, Report pill + menu.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InitialAvatar(
                  initials: _getInitials(post.authorName),
                  color: _avatarColor(post.authorName),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
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
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              postedAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Fix #4: no Report pill on your own posts (menu has
                // Edit/Delete instead).
                if (!widget.isPostOwn)
                  InkWell(
                    onTap: () => _openReport(
                      targetId: post.id,
                    targetKind: 'post',
                    alreadyReported: widget.isPostReported,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mistPaper,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPostReported
                              ? Icons.flag_rounded
                              : Icons.flag_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lang.t('forum_report'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: lang.t('forum_report'),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  onSelected: (value) {
                    if (value == 'report') {
                      _openReport(
                        targetId: post.id,
                        targetKind: 'post',
                        alreadyReported: widget.isPostReported,
                      );
                    } else if (value == 'edit') {
                      _openEditPost();
                    } else if (value == 'delete') {
                      _confirmDelete(isReply: false, replyId: '');
                    } else if (value == 'copy') {
                      HapticFeedback.lightImpact().catchError((_) {});
                      // System shows its own "Copied" overlay (Android 13+).
                      Clipboard.setData(ClipboardData(text: post.message));
                    }
                  },
                  itemBuilder: (context) {
                    // Fix #4: your own posts offer Edit/Delete (edit only
                    // inside the window); everyone else's offers Report.
                    if (widget.isPostOwn) {
                      return [
                        if (widget.canEditPost)
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(lang.t('forum_edit')),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(lang.t('forum_delete')),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy text'),
                        ),
                      ];
                    }
                    return [
                      PopupMenuItem(
                        value: 'report',
                        child: Text(lang.t('forum_report')),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Text('Copy text'),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              post.message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),

            // Fix #3: this post failed to upload — keep it visible and
            // let the visitor retry instead of silently losing it.
            if (post.pendingSync) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact().catchError((_) {});
                  widget.onRetrySend();
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Unsent · Tap to retry',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Simple text actions: heart Puso + count | divider | N replies.
            // The like count (when > 0) opens the likers sheet.
            // Tapping replies expands the thread and opens the composer;
            // person-level Reply buttons handle @mentions.
            Row(
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact().catchError((_) {});
                    widget.onReactionTap('heart');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: liked
                              ? _LikeRed.color
                              : AppColors.warmMid,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.t('forum_like'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: liked
                                ? _LikeRed.color
                                : AppColors.warmMid,
                          ),
                        ),
                        if (heartCount > 0) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact()
                                  .catchError((_) {});
                              LikersSheet.show(
                                context,
                                loadNames: () =>
                                    widget.onViewLikers(post.id),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Text(
                                '$heartCount',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: liked
                                      ? _LikeRed.color
                                      : AppColors.warmMid,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.stoneBorder,
                ),
                const SizedBox(width: 12),
                _TextAction(
                  icon: _repliesExpanded
                      ? Icons.chat_bubble_rounded
                      : Icons.chat_bubble_outline_rounded,
                  label: post.replies.length == 1
                      ? '1 reply'
                      : '${post.replies.length} replies',
                  onTap: _toggleRepliesThread,
                ),
              ],
            ),

            if (showRepliesBlock) ...[
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: AppColors.stoneBorder.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: const EdgeInsets.only(left: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.stoneBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < visibleReplies.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == visibleReplies.length - 1 &&
                                    !showMoreButton
                                ? 0
                                : 16,
                            // Mockup nesting: @-replies sit one level
                            // deeper than top-level replies.
                            left: visibleReplies[i]
                                    .replyToName
                                    .trim()
                                    .isNotEmpty
                                ? 24
                                : 0,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Curve elbow only for reply-to-reply
                              // (nested). Top-level replies connect
                              // straight to the rail with no curve.
                              if (visibleReplies[i]
                                  .replyToName
                                  .trim()
                                  .isNotEmpty) ...[
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: AppColors.stoneBorder,
                                        width: 1.5,
                                      ),
                                      bottom: BorderSide(
                                        color: AppColors.stoneBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: _InlineReply(
                                  reply: visibleReplies[i],
                                  initials: _getInitials(
                                    visibleReplies[i].authorName,
                                  ),
                                  shortDate: _formatShort(
                                    context,
                                    visibleReplies[i].createdAt,
                                  ),
                                  onReactionTap: (type) => widget
                                      .onReplyReactionTap(
                                    visibleReplies[i].id,
                                    type,
                                  ),
                                  onViewLikers: () =>
                                      LikersSheet.show(
                                    context,
                                    loadNames: () =>
                                        widget.onViewLikers(
                                      visibleReplies[i].id,
                                    ),
                                  ),
                                  onReplyTap: () => _targetReply(
                                    visibleReplies[i].authorName,
                                  ),
                                  knownNames: knownNames,
                                  isReported:
                                      widget.isReplyReported(
                                    visibleReplies[i].id,
                                  ),
                                  onReportTap: () => _openReport(
                                    targetId:
                                        visibleReplies[i].id,
                                    targetKind: 'reply',
                                    alreadyReported:
                                        widget.isReplyReported(
                                      visibleReplies[i].id,
                                    ),
                                  ),
                                  isOwn: widget.isReplyOwn(
                                    visibleReplies[i].id,
                                  ),
                                  canEdit: widget.canEditReply(
                                    visibleReplies[i].id,
                                  ),
                                  onEditTap: () => _openEditReply(
                                    visibleReplies[i],
                                  ),
                                  onDeleteTap: () => _confirmDelete(
                                    isReply: true,
                                    replyId: visibleReplies[i].id,
                                  ),
                                  onRetrySend: () => widget.onRetryReplySend(
                                    visibleReplies[i].id,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (showMoreButton)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: _expandThreadOnly,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 6,
                              ),
                              child: Text(
                                lang.t('forum_show_more_short'),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warmMid,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Reply-gated composer: hidden until an explicit Reply tap.
            if (_composerOpen) const SizedBox(height: 16),
            if (_composerOpen)
              Column(
              key: _composerKey,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_replyTarget != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lang.t(
                              'forum_replying_to',
                              {'name': _replyTarget!},
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _clearTarget,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 6,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.stoneBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_replyTarget != null &&
                            _replyTarget!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              '@${_replyTarget!.trim()} ',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.roseDeep,
                              ),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _composerController,
                            focusNode: _composerFocus,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 1000,
                            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                            enabled: !_sending,
                            onSubmitted: (_) => _handleSend(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: lang.t('forum_write_reply_hint'),
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: _sending ? null : _handleSend,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.warmDark,
                          disabledBackgroundColor: AppColors.warmDark
                              .withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat reply row: small avatar + name/date + message + heart/Reply.
/// No bubble, no rail — matches the minimal reference.
class _InlineReply extends StatelessWidget {
  final ForumReply reply;
  final String initials;
  final String shortDate;
  final void Function(String reactionType) onReactionTap;
  final VoidCallback onViewLikers;
  final VoidCallback onReplyTap;
  final List<String> knownNames;
  final bool isReported;
  final VoidCallback onReportTap;
  /// True when this reply was created on this device (fix #4).
  final bool isOwn;
  /// True when your own reply is still inside the edit window.
  final bool canEdit;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  /// Re-uploads this unsent (pendingSync) reply. Best-effort.
  final VoidCallback onRetrySend;

  const _InlineReply({
    required this.reply,
    required this.initials,
    required this.shortDate,
    required this.onReactionTap,
    required this.onViewLikers,
    required this.onReplyTap,
    this.knownNames = const [],
    this.isReported = false,
    required this.onReportTap,
    this.isOwn = false,
    this.canEdit = false,
    this.onEditTap = _noop,
    this.onDeleteTap = _noop,
    this.onRetrySend = _noop,
  });

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final liked = reply.userReactions.contains('heart');
    final count = reply.reactions['heart'] ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _avatarColor(reply.authorName),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warmDeep,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // flex: 0 — must not share free space with the date
                  // below, or the leftover dead space parks the menu
                  // mid-row instead of at the trailing edge.
                  Flexible(
                    flex: 0,
                    child: Text(
                      reply.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shortDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  // Fixed 28px box so the dots sit exactly at the
                  // trailing edge, never floating mid-row.
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      tooltip: lang.t('forum_report'),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    onSelected: (value) {
                      if (value == 'report') {
                        onReportTap();
                      } else if (value == 'edit') {
                        onEditTap();
                      } else if (value == 'delete') {
                        onDeleteTap();
                      } else if (value == 'copy') {
                        HapticFeedback.lightImpact().catchError((_) {});
                        Clipboard.setData(
                          ClipboardData(text: reply.message),
                        );
                      }
                    },
                    itemBuilder: (context) {
                      // Fix #4: your own replies offer Edit/Delete (edit
                      // only inside the window); others offer Report.
                      if (isOwn) {
                        return [
                          if (canEdit)
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(lang.t('forum_edit')),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(lang.t('forum_delete')),
                          ),
                          const PopupMenuItem(
                            value: 'copy',
                            child: Text('Copy text'),
                          ),
                        ];
                      }
                      return [
                        PopupMenuItem(
                          value: 'report',
                          child: Text(lang.t('forum_report')),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy text'),
                        ),
                      ];
                    },
                    ),
                  ),
                ],
              ),
              if (reply.replyToName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 11,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        lang.t(
                          'forum_replying_to',
                          {'name': reply.replyToName},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              _MentionMessageText(
                message: reply.message,
                replyToName: reply.replyToName,
                knownNames: knownNames,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact().catchError((_) {});
                      onReactionTap('heart');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 15,
                            color: liked
                                ? _LikeRed.color
                                : AppColors.warmMid,
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact()
                                    .catchError((_) {});
                                onViewLikers();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    fontWeight: liked
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: liked
                                        ? _LikeRed.color
                                        : AppColors.warmMid,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact().catchError((_) {});
                      onReplyTap();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warmMid,
                        ),
                      ),
                    ),
                  ),
                  // Fix #3: this reply failed to upload — keep it visible
                  // and let the visitor retry instead of silently
                  // losing it.
                  if (reply.pendingSync)
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact().catchError((_) {});
                        onRetrySend();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
                        child: Text(
                          'Unsent · retry',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// @mention in memorial blue bold, rest in body ink.
/// Matches full names ("@Juan Dela Cruz") via [replyToName] first, then
/// any known thread author, so multi-word names never truncate to "@Juan".
class _MentionMessageText extends StatelessWidget {
  final String message;
  final String replyToName;
  final List<String> knownNames;

  const _MentionMessageText({
    required this.message,
    this.replyToName = '',
    this.knownNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.5,
      color: AppColors.textDark,
    );
    String? mention;
    String rest = message;
    final target = replyToName.trim();
    if (target.isNotEmpty && message.startsWith('@$target')) {
      mention = '@$target';
      rest = message.substring(mention.length);
    } else {
      final sorted = List<String>.from(knownNames)
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final name in sorted) {
        final clean = name.trim();
        if (clean.isEmpty) continue;
        if (message.startsWith('@$clean')) {
          mention = '@$clean';
          rest = message.substring(mention.length);
          break;
        }
      }
    }
    if (mention == null) {
      final match = RegExp(r'^(@\S+)\s*').firstMatch(message);
      if (match == null) {
        return Text(message, style: baseStyle);
      }
      mention = match.group(1)!;
      rest = message.substring(match.end);
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: mention,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: _MentionBlue.color,
              ),
            ),
            if (rest.isNotEmpty)
              TextSpan(
                text: '${rest.startsWith(' ') ? '' : ' '}$rest',
                style: baseStyle,
              ),
          ],
        ),
      );
    }
    rest = rest.trimLeft();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: mention,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: _MentionBlue.color,
            ),
          ),
          if (rest.isNotEmpty)
            TextSpan(
              text: '${rest.startsWith(' ') ? '' : ' '}$rest',
              style: baseStyle,
            ),
        ],
      ),
    );
  }
}

/// Pastel avatar background picked from the name hash, so each visitor
/// keeps one stable color (mockup: cream, mint, lavender, ...).
Color _avatarColor(String name) {
  const palette = [
    Color(0xFFF3E3C2),
    Color(0xFFD9E9E0),
    Color(0xFFDED9F2),
    Color(0xFFF2DCCD),
    Color(0xFFD5E4F5),
  ];
  final clean = name.trim();
  if (clean.isEmpty) return palette[0];
  var hash = 0;
  for (final unit in clean.toUpperCase().codeUnits) {
    hash = (hash + unit) % 0x7FFFFFFF;
  }
  return palette[hash % palette.length];
}

/// Flat 34px pastel avatar, warmDeep initial. No gradient, no ring.
class _InitialAvatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _InitialAvatar({
    required this.initials,
    this.color = const Color(0xFFF3E3C2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.warmDeep,
          ),
        ),
      ),
    );
  }
}

/// True heart-red for liked state (not brown).
class _LikeRed {
  static const color = Color(0xFFD92D20);
}

/// Memorial blue for @mentions (mockup style).
class _MentionBlue {
  static const color = Color(0xFF2B5CE6);
}

/// Flat text action: icon + label, no fill, no border.
class _TextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppColors.warmMid;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact().catchError((_) {});
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
