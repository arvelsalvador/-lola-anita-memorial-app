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
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;
  final Set<String> _seenIds = {};
  int? _prevTotal;

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
            else if (posts.isEmpty && controller.loadError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 28,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang.t('forum_load_error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.warmMid,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact().catchError((_) {});
                        controller.loadPosts();
                        controller.subscribeRealtime().catchError((_) {});
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        lang.t('forum_retry'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.stoneBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
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
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                ),
              )
            else ...[
              ...() {
                // Keep what the user already sees when live posts arrive
                // at the top: grow the window by the delta so the bottom
                // card isn't pushed out.
                if (_prevTotal != null && posts.length > _prevTotal!) {
                  _visibleCount += posts.length - _prevTotal!;
                }
                _prevTotal = posts.length;
                if (_visibleCount > posts.length) {
                  _visibleCount = posts.length;
                }
                // Paginate: first paint builds max 20 cards, not 100.
                final visible =
                    posts.take(_visibleCount).toList();
                // Animate only live arrivals, never the initial load.
                // First build marks everything seen with no animation,
                // so 100 cached posts cost zero AnimationControllers.
                final bool wasFirstBuild = _seenIds.isEmpty;
                final currentIds =
                    posts.map((p) => p.id).toSet();
                final Set<String> newIds = wasFirstBuild
                    ? <String>{}
                    : currentIds.difference(_seenIds);
                // Prune deleted ids so the set stays bounded.
                _seenIds.retainAll(currentIds);
                _seenIds.addAll(currentIds);
                final bool isInitialLoad = wasFirstBuild;

                Widget buildCard(post) {
                  final card = RepaintBoundary(
                    child: ForumPostCard(
                      key: ValueKey(post.id),
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
                      isPostReported: controller.isReported(post.id),
                      isReplyReported: (replyId) =>
                          controller.isReported(replyId),
                      onSubmitReport:
                          (targetId, targetKind, reason, details) {
                        return controller.reportTarget(
                          targetId: targetId,
                          targetKind: targetKind,
                          reason: reason,
                          details: details,
                        );
                      },
                      isPostOwn: controller.isOwnPost(post.id),
                      canEditPost: controller.canEditPost(post.id),
                      isReplyOwn: (replyId) =>
                          controller.isOwnReply(replyId),
                      canEditReply: (replyId) => controller.canEditReply(
                        post.id,
                        replyId,
                      ),
                      onEditPost: (message) => controller.editPost(
                        postId: post.id,
                        message: message,
                      ),
                      onDeletePost: () =>
                          controller.deletePost(post.id),
                      onEditReply: (replyId, message) =>
                          controller.editReply(
                        postId: post.id,
                        replyId: replyId,
                        message: message,
                      ),
                      onDeleteReply: (replyId) => controller.deleteReply(
                        postId: post.id,
                        replyId: replyId,
                      ),
                    ),
                  );
                  if (isInitialLoad || !newIds.contains(post.id)) {
                    return card;
                  }
                  return _LiveInsertWrapper(
                    key: ValueKey('anim-${post.id}'),
                    child: card,
                  );
                }

                final widgets =
                    visible.map(buildCard).toList();
                if (_visibleCount < posts.length) {
                  final remaining = posts.length - _visibleCount;
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact()
                              .catchError((_) {});
                          setState(() {
                            _visibleCount += _pageSize;
                          });
                        },
                        icon: const Icon(
                            Icons.expand_more_rounded,
                            size: 16),
                        label: Text(
                          lang.t('forum_show_more',
                              {'remaining': '$remaining'}),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppColors.stoneBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return widgets;
              }(),
            ],
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
              fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            // Elderly-friendly manual refresh: same reload as
            // pull-to-refresh, 44px target with a text tooltip.
            IconButton(
              tooltip: lang.t('forum_refresh'),
              onPressed: () {
                HapticFeedback.lightImpact().catchError((_) {});
                onRetry();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: AppColors.warmMid,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: EdgeInsets.zero,
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
                  fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
