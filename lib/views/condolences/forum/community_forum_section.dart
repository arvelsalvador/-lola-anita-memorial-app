import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/forum/create_post_dialog.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';

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
                  onReplyReactionTap: (replyId, reactionType) {
                    forumController.toggleReplyReaction(
                      post.id,
                      replyId,
                      reactionType,
                    );
                  },
                  onSendReply: (authorName, message, replyToName) {
                    return forumController.addReply(
                      postId: post.id,
                      authorName: authorName,
                      message: message,
                      replyToName: replyToName,
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sandBorder.withValues(alpha: 0.9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.iconBgCream,
                ),
                child: const Center(
                  child: Icon(
                    Icons.layers_outlined,
                    size: 20,
                    color: AppColors.warmDeep,
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
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 12.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Outlined public pill with people icon.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.sandBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 12,
                            color: AppColors.warmMid,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              lang.t('forum_public_note'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 11.5,
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
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact().catchError((_) {});
                onShareTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmDark,
                foregroundColor: AppColors.linen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: AppColors.warmDark.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.t('forum_share_button'),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    right: 0,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
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
