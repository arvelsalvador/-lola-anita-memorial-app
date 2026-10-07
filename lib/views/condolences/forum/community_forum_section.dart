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

    // Flat minimal header (Image 1 bottom): hairline divider, left
    // title, globe public note, full-width outlined share button.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 1,
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.public_outlined,
              size: 14,
              color: AppColors.muted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lang.t('forum_public_note'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        // Subtitle kept for screen readers, visually hidden to match
        // the minimal reference (title + public note only).
        Semantics(
          header: true,
          child: ExcludeSemantics(
            excluding: false,
            child: SizedBox.shrink(
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 0.1, color: Colors.transparent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact().catchError((_) {});
              onShareTap();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.stoneBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    lang.t('forum_share_button'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
