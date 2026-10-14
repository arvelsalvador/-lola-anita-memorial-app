import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/forum/create_post_dialog.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';

/// The community messages & stories board connected directly to the database.
///
/// Subscribes to Supabase Realtime on mount so posts, replies, and likes
/// from other visitors appear without refresh.
class CommunityForumSection extends StatefulWidget {
  final ForumController forumController;

  const CommunityForumSection({super.key, required this.forumController});

  @override
  State<CommunityForumSection> createState() => _CommunityForumSectionState();
}

class _CommunityForumSectionState extends State<CommunityForumSection> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: no-op when offline or already subscribed.
    widget.forumController.subscribeRealtime().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return ListenableBuilder(
      listenable: widget.forumController,
      builder: (context, _) {
        final controller = widget.forumController;
        final posts = controller.posts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            _ForumHeader(
              title: lang.t('forum_title'),
              subtitle: lang.t('forum_subtitle'),
              live: controller.realtimeConnected,
              onRetry: () {
                controller.loadPosts();
                controller.subscribeRealtime().catchError((_) {});
              },
              onShareTap: () {
                CreatePostDialog.show(context, controller: controller);
              },
            ),

            const SizedBox(height: 16),

            // Posts Feed
            if (controller.loading && posts.isEmpty)
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
                (post) => _LiveInsertWrapper(
                  key: ValueKey(post.id),
                  child: ForumPostCard(
                    post: post,
                    isPostAuthorOnline:
                        controller.isOnline(post.authorName),
                    isReplyAuthorOnline: (name) =>
                        controller.isOnline(name),
                    onViewLikers: (targetId) =>
                        controller.likerNames(targetId),
                    onReactionTap: (reactionType) {
                      controller.toggleReaction(post.id, reactionType);
                    },
                    onReplyReactionTap: (replyId, reactionType) {
                      controller.toggleReplyReaction(
                        post.id,
                        replyId,
                        reactionType,
                      );
                    },
                    onSendReply: (authorName, message, replyToName) {
                      return controller.addReply(
                        postId: post.id,
                        authorName: authorName,
                        message: message,
                        replyToName: replyToName,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Fades + slides a newly inserted card in so live arrivals don't jolt.
class _LiveInsertWrapper extends StatefulWidget {
  final Widget child;

  const _LiveInsertWrapper({super.key, required this.child});

  @override
  State<_LiveInsertWrapper> createState() => _LiveInsertWrapperState();
}

class _LiveInsertWrapperState extends State<_LiveInsertWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Green LIVE pill when the realtime socket is up; muted offline note
/// with a retry tap when showing cached posts.
class _LiveBadge extends StatelessWidget {
  final bool live;
  final VoidCallback onRetry;

  const _LiveBadge({required this.live, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (live) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF1F9D55),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFF1F9D55),
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact().catchError((_) {});
        onRetry();
      },
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 13, color: AppColors.muted),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Offline • showing saved — tap to retry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool live;
  final VoidCallback onRetry;
  final VoidCallback onShareTap;

  const _ForumHeader({
    required this.title,
    required this.subtitle,
    required this.live,
    required this.onRetry,
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
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            _LiveBadge(live: live, onRetry: onRetry),
          ],
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
