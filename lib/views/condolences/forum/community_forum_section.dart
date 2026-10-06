import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/forum/create_post_dialog.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';
import 'package:nita/views/condolences/forum/forum_reply_sheet.dart';

/// The community messages & stories board connected directly to the database.
class CommunityForumSection extends StatelessWidget {
  final ForumController forumController;

  const CommunityForumSection({super.key, required this.forumController});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return ListenableBuilder(
      listenable: forumController,
      builder: (context, _) {
        final posts = forumController.posts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            _ForumHeader(
              title: lang.t('forum_title'),
              subtitle: lang.t('forum_subtitle'),
              onShareTap: () {
                CreatePostDialog.show(context, controller: forumController);
              },
            ),

            const SizedBox(height: 16),

            // Posts Feed
            if (forumController.loading && posts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              )
            else if (posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Text(
                    lang.t('forum_empty_state'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                ),
              )
            else
              ...posts.map(
                (post) => ForumPostCard(
                  key: ValueKey(post.id),
                  post: post,
                  onReactionTap: (reactionType) {
                    forumController.toggleReaction(post.id, reactionType);
                  },
                  onReplyTap: () {
                    ForumReplySheet.show(
                      context,
                      post: post,
                      controller: forumController,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ForumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onShareTap;

  const _ForumHeader({
    required this.title,
    required this.subtitle,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.roseLight,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.roseDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 12,
                        color: AppColors.warmMid,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Compact public pill: single line, matches candle side.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            size: 11,
                            color: AppColors.warmMid,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              lang.t('forum_public_note'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.warmMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact().catchError((_) {});
                onShareTap();
              },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(
                lang.t('forum_share_button'),
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmDark,
                foregroundColor: AppColors.linen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
