import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/forum_post_model.dart';

/// Minimal flat message card (Image 1 port, warm-adapted):
/// paper card, flat avatars, text-only actions, divider, flat replies,
/// pill composer. Lora + memorial tokens kept — no blue, no sans.
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

  /// Full date for the main post: "Okt 6, 2026".
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

  /// Short date for replies: "Okt 7".
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
    return '$month ${local.day}';
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
    final hasReplies = post.replies.isNotEmpty;
    final showThread = _repliesExpanded && hasReplies;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stoneBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name over date (no calendar icon).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InitialAvatar(initials: _getInitials(post.authorName)),
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
                          fontFamily: 'Lora',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        postedAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              post.message,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 15,
                height: 1.55,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 12),

            // Flat text actions: Like | N replies | Reply.
            Row(
              children: [
                _TextAction(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  active: liked,
                  onTap: () => widget.onReactionTap('heart'),
                ),
                const SizedBox(width: 20),
                _TextAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: post.replies.length == 1
                      ? '1 reply'
                      : '${post.replies.length} replies',
                  onTap: () {
                    HapticFeedback.lightImpact().catchError((_) {});
                    setState(
                      () => _repliesExpanded = !_repliesExpanded,
                    );
                  },
                ),
                const SizedBox(width: 20),
                _TextAction(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: _replyToPost,
                ),
              ],
            ),

            if (showThread) ...[
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: AppColors.stoneBorder.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < post.replies.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == post.replies.length - 1 ? 0 : 16,
                  ),
                  child: _InlineReply(
                    reply: post.replies[i],
                    initials: _getInitials(post.replies[i].authorName),
                    shortDate:
                        _formatShort(context, post.replies[i].createdAt),
                    onReactionTap: (type) => widget.onReplyReactionTap(
                      post.replies[i].id,
                      type,
                    ),
                    onReplyTap: () =>
                        _targetReply(post.replies[i].authorName),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Pill composer.
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
                              fontFamily: 'Lora',
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
                ],
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
                              fontFamily: 'Lora',
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
                          minLines: 1,
                          maxLines: 3,
                          enabled: !_sending,
                          onSubmitted: (_) => _handleSend(),
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: lang.t('forum_write_reply_hint'),
                            hintStyle: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
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
  final VoidCallback onReplyTap;

  const _InlineReply({
    required this.reply,
    required this.initials,
    required this.shortDate,
    required this.onReactionTap,
    required this.onReplyTap,
  });

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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mistPaper,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Lora',
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
                children: [
                  Flexible(
                    child: Text(
                      reply.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shortDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 12,
                      color: AppColors.muted,
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
                          fontFamily: 'Lora',
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
              _MentionMessageText(message: reply.message),
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
                            Text(
                              '$count',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12.5,
                                fontWeight: liked
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: liked
                                    ? _LikeRed.color
                                    : AppColors.warmMid,
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
                          fontFamily: 'Lora',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warmMid,
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

/// @mention in roseDeep bold, rest in body ink.
class _MentionMessageText extends StatelessWidget {
  final String message;

  const _MentionMessageText({required this.message});

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Lora',
      fontSize: 14,
      height: 1.5,
      color: AppColors.textDark,
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
              color: AppColors.roseDeep,
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

/// Flat 40px beige avatar, roseDeep initial. No gradient, no ring.
class _InitialAvatar extends StatelessWidget {
  final String initials;

  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.iconBgCream,
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

/// True heart-red for liked state (not brown).
class _LikeRed {
  static const color = Color(0xFFD92D20);
}

/// Flat text action: icon + label, no fill, no border.
class _TextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TextAction({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _LikeRed.color : AppColors.warmMid;
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 13.5,
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
