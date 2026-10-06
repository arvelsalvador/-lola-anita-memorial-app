import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/widgets/gradient_avatar.dart';

/// A single message / story card in the community board.
class ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onReplyTap;
  final void Function(String reactionType) onReactionTap;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.onReplyTap,
    required this.onReactionTap,
  });

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final lang = context.read<LanguageProvider>();
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 60) {
      return lang.t('forum_just_now');
    } else if (diff.inHours < 24) {
      return lang.t('forum_hours_ago', {'count': '${diff.inHours}'});
    } else {
      return lang.t('forum_days_ago', {'count': '${diff.inDays}'});
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final timeAgo = _formatTimeAgo(context, post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sandBorder.withValues(alpha: 0.9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top author row
            Row(
              children: [
                GradientAvatar(
                  initials: _getInitials(post.authorName),
                  size: 36,
                  initialsSize: 13,
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
                          fontFamily: 'Lora',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message text
            Text(
              post.message,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF4A382D),
              ),
            ),

            const SizedBox(height: 12),

            // Divider hairline
            Container(
              height: 0.6,
              color: AppColors.sandBorder.withValues(alpha: 0.7),
            ),

            const SizedBox(height: 8),

            // Action toolbar: Reactions + Reply button
            Row(
              children: [
                _ReactionItem(
                  icon: '🕯️',
                  count: post.reactions['candle'] ?? 0,
                  active: post.userReactions.contains('candle'),
                  onTap: () => onReactionTap('candle'),
                ),
                const SizedBox(width: 4),
                _ReactionItem(
                  icon: '🕊️',
                  count: post.reactions['dove'] ?? 0,
                  active: post.userReactions.contains('dove'),
                  onTap: () => onReactionTap('dove'),
                ),
                const SizedBox(width: 4),
                _ReactionItem(
                  icon: '❤️',
                  count: post.reactions['heart'] ?? 0,
                  active: post.userReactions.contains('heart'),
                  onTap: () => onReactionTap('heart'),
                ),
                const SizedBox(width: 4),
                _ReactionItem(
                  icon: '🙏',
                  count: post.reactions['pray'] ?? 0,
                  active: post.userReactions.contains('pray'),
                  onTap: () => onReactionTap('pray'),
                ),

                const Spacer(),

                // Reply button
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact().catchError((_) {});
                    onReplyTap();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mistPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: AppColors.warmMid,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          post.replies.isEmpty
                              ? lang.t('forum_reply_action')
                              : '${post.replies.length}',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warmMid,
                          ),
                        ),
                      ],
                    ),
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

class _ReactionItem extends StatelessWidget {
  final String icon;
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact().catchError((_) {});
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.goldLight.withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.warmDark : AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
