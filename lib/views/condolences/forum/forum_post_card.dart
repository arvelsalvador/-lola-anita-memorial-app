import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/forum_post_model.dart';

/// A single message / story card in the community board.
/// No popup / bottom sheet — everything happens inline on the card:
/// each reply has its own reply-arrow button so people can talk
/// person-to-person, tapping it targets the bottom box at that person
/// ("Tumutugon kay X" + @mention) and pops the phone keyboard instantly.
class ForumPostCard extends StatefulWidget {
  final ForumPost post;
  final void Function(String reactionType) onReactionTap;
  final void Function(String replyId, String reactionType) onReplyReactionTap;
  final Future<void> Function(
    String authorName,
    String message,
    String replyToName,
  ) onSendReply;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.onReactionTap,
    required this.onReplyReactionTap,
    required this.onSendReply,
  });

  @override
  State<ForumPostCard> createState() => _ForumPostCardState();
}

class _ForumPostCardState extends State<ForumPostCard> {
  String? _replyTarget;
  bool _repliesExpanded = true;

  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final GlobalKey _composerKey = GlobalKey();
  final VisitorRepository _visitorRepo = const VisitorRepository();
  String _visitorName = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadVisitorName();
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
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _targetReply(String authorName) {
    final name = authorName.trim();
    if (name.isEmpty) return;
    HapticFeedback.lightImpact().catchError((_) {});
    final current = _composerController.text;
    final stripped = current.replaceFirst(RegExp(r'^@\S+\s*'), '');
    setState(() {
      _replyTarget = name;
      _repliesExpanded = true;
      // Mention lives as a bold prefix widget, not editable text.
      _composerController.text = stripped;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
    });
    // Instant keyboard on phone: focus after frame so the box is laid out,
    // then ensure it is visible above the keyboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _composerFocus.requestFocus();
      final ctx = _composerKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.9,
        ).catchError((_) {});
      }
    });
  }

  void _replyToPost() {
    HapticFeedback.lightImpact().catchError((_) {});
    final current = _composerController.text;
    final stripped = current.replaceFirst(RegExp(r'^@\S+\s*'), '');
    setState(() {
      _replyTarget = null;
      _repliesExpanded = true;
      _composerController.text = stripped;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _composerFocus.requestFocus();
      final ctx = _composerKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.9,
        ).catchError((_) {});
      }
    });
  }

  void _clearTarget() {
    HapticFeedback.lightImpact().catchError((_) {});
    final current = _composerController.text;
    final stripped = current.replaceFirst(RegExp(r'^@\S+\s*'), '');
    setState(() {
      _replyTarget = null;
      _composerController.text = stripped;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
    });
  }

  Future<void> _handleSend() async {
    final body = _composerController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.lightImpact().catchError((_) {});
    try {
      final author = _visitorName.isEmpty ? 'Anonymous' : _visitorName;
      final target = (_replyTarget ?? '').trim();
      // Combine bold prefix + typed body; avoid doubling @ if typed manually.
      final startsWithMention =
          target.isNotEmpty && body.startsWith('@$target');
      final text =
          target.isNotEmpty && !startsWithMention ? '@$target $body' : body;
      await widget.onSendReply(author, text, target);
      if (mounted) {
        _composerController.clear();
        setState(() {
          _replyTarget = null;
          _repliesExpanded = true;
        });
        _composerFocus.unfocus();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Date only: "Okt 6, 2026". Month abbreviations follow the active
  /// language (Ene/Peb/... for TL/BI, Jan/Feb for EN). No time —
  /// every post shows its exact date on the right side of the bar.
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
    return '$month ${local.day}, ${local.year}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final postedAt = _formatExact(context, post.createdAt);
    final lang = context.watch<LanguageProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top author row: avatar + name on the left,
            // date at the right end of the bar.
            Row(
              children: [
                _InitialAvatar(initials: _getInitials(post.authorName)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: AppColors.terracotta,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      postedAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Message text
            Text(
              post.message,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 15,
                height: 1.55,
                color: Color(0xFF4A382D),
              ),
            ),

            const SizedBox(height: 10),

            // Action toolbar: Heart + show/hide pill + reply-to-author.
            Row(
              children: [
                _ReactionItem(
                  icon: Icons.favorite_border,
                  count: post.reactions['heart'] ?? 0,
                  active: post.userReactions.contains('heart'),
                  onTap: () => widget.onReactionTap('heart'),
                ),
                const SizedBox(width: 6),

                // Show / hide replies pill — no popup, only expands thread.
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact().catchError((_) {});
                    setState(
                      () => _repliesExpanded = !_repliesExpanded,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: AppColors.roseDeep,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.replies.length}',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.roseDeep,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _repliesExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 14,
                          color: AppColors.roseDeep,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Reply to the main message — no mention, just focus
                // the box. Mentions only happen on reply-to-reply.
                Tooltip(
                  message: 'Reply',
                  child: InkWell(
                    onTap: _replyToPost,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          width: 0.7,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 15,
                            color: AppColors.roseDeep,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Inline replies: shown by default, indented under the
            // parent message with a thread rail on the left.
            // Each reply has its own reply-arrow so people can answer
            // each other person-to-person.
            if (_repliesExpanded && post.replies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.rose.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < post.replies.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                i == post.replies.length - 1 ? 0 : 10,
                          ),
                          child: _InlineReply(
                            reply: post.replies[i],
                            initials:
                                _getInitials(post.replies[i].authorName),
                            timeAgo: _formatExact(
                              context,
                              post.replies[i].createdAt,
                            ),
                            onReactionTap: (type) =>
                                widget.onReplyReactionTap(
                              post.replies[i].id,
                              type,
                            ),
                            onReplyTap: () =>
                                _targetReply(post.replies[i].authorName),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Inline composer: always on the card, no sheet.
            const SizedBox(height: 10),
            Column(
              key: _composerKey,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_replyTarget != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 12,
                          color: AppColors.gold,
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
                              fontFamily: 'Lora',
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.warmMid,
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
                              size: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blushPaper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.rose.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bold mention prefix while typing — matches the
                      // bold mention shown after send.
                      if (_replyTarget != null &&
                          _replyTarget!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '@${_replyTarget!.trim()} ',
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmDeep,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _composerController,
                          focusNode: _composerFocus,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 3,
                          enabled: !_sending,
                          onSubmitted: (_) => _handleSend(),
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: lang.t('forum_write_reply_hint'),
                            hintStyle: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: _sending ? null : _handleSend,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(34, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.linen,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 15),
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

/// One inline reply: small beige avatar + name/time row + message +
/// its own reaction chip + its own reply-arrow so anyone can answer
/// that specific person inline (no popup).
class _InlineReply extends StatelessWidget {
  final ForumReply reply;
  final String initials;
  final String timeAgo;
  final void Function(String reactionType) onReactionTap;
  final VoidCallback onReplyTap;

  const _InlineReply({
    required this.reply,
    required this.initials,
    required this.timeAgo,
    required this.onReactionTap,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.roseLight,
                AppColors.goldLight.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.roseDeep,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBDD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.rose.withValues(alpha: 0.28),
                width: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reply.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                // Context line: shows whose message this answers.
                if (reply.replyToName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 10,
                        color: AppColors.gold,
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
                            fontFamily: 'Lora',
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.warmMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 3),
                _MentionMessageText(message: reply.message),
                const SizedBox(height: 6),
                // Heart + reply side by side so each reply can be
                // answered person-to-person inline (no popup).
                Row(
                  children: [
                    _ReactionItem(
                      icon: Icons.favorite_border,
                      count: reply.reactions['heart'] ?? 0,
                      active: reply.userReactions.contains('heart'),
                      onTap: () => onReactionTap('heart'),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Reply to ${reply.authorName}',
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact().catchError((_) {});
                          onReplyTap();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.gold.withValues(alpha: 0.45),
                              width: 0.7,
                            ),
                          ),
                          child: const Icon(
                            Icons.reply_rounded,
                            size: 15,
                            color: AppColors.roseDeep,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reply message text with the leading @mention in bold so it never
/// blends into the rest of the message (e.g. "@Anonymous oo nga eh").
class _MentionMessageText extends StatelessWidget {
  final String message;

  const _MentionMessageText({required this.message});

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Lora',
      fontSize: 13,
      height: 1.5,
      color: Color(0xFF4A382D),
    );
    final match = RegExp(r'^(@\S+)\s*').firstMatch(message);
    if (match == null) {
      return Text(message, style: baseStyle);
    }
    final mention = match.group(1)!;
    final rest = message.substring(match.end);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: mention,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.warmDeep,
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

/// Warm gradient initials avatar per DESIGN.md: rose-light → gold-light
/// diagonal at 60% alpha, ringed by a gold hairline, initials in rose deep.
class _InitialAvatar extends StatelessWidget {
  final String initials;

  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.roseLight,
            AppColors.goldLight.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.roseDeep,
          ),
        ),
      ),
    );
  }
}

/// Reaction chip with smooth hover + tap feedback: hovering (desktop/web)
/// gently grows the chip, pressing springs it up to 1.4x before settling
/// back, and the count cross-fades whenever it changes.
class _ReactionItem extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _ReactionItem({
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem> {
  bool _hovering = false;
  bool _pressing = false;

  double get _scale {
    if (_pressing) return 1.4;
    if (_hovering) return 1.15;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact().catchError((_) {});
        widget.onTap();
      },
      onHighlightChanged: (pressed) {
        if (mounted) setState(() => _pressing = pressed);
      },
      onHover: (hovering) {
        if (mounted) setState(() => _hovering = hovering);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.active
                  ? AppColors.rose
                  : AppColors.goldLight.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.active
                    ? AppColors.roseDeep.withValues(alpha: 0.5)
                    : AppColors.gold.withValues(alpha: 0.45),
                width: 0.7,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.active ? Icons.favorite_rounded : widget.icon,
                  size: 14,
                  color: widget.active ? Colors.white : AppColors.terracotta,
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: widget.count > 0
                    ? Row(
                        key: ValueKey(widget.count),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            '${widget.count}',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              fontWeight: widget.active
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: widget.active
                                  ? Colors.white
                                  : AppColors.roseDeep,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
