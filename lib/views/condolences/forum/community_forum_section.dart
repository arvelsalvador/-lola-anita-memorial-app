import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/views/condolences/forum/create_post_dialog.dart';
import 'package:nita/views/condolences/forum/forum_post_card.dart';
import 'package:nita/widgets/reveal_on_appear.dart';

/// The community messages & stories board connected directly to the database.
///
/// Subscribes to Supabase Realtime on mount so posts, replies, and likes
/// from other visitors appear without refresh.
class CommunityForumSection extends StatefulWidget {
  final ForumController forumController;

  final GlobalKey? forumHeaderKey;
  final GlobalKey? firstPostActionsKey;

  const CommunityForumSection({
    super.key,
    required this.forumController,
    this.forumHeaderKey,
    this.firstPostActionsKey,
  });

  @override
  State<CommunityForumSection> createState() => _CommunityForumSectionState();
}

class _CommunityForumSectionState extends State<CommunityForumSection>
    with WidgetsBindingObserver {
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;
  final Set<String> _seenIds = {};
  int? _prevTotal;
  bool _disposed = false;
  // Ids that arrived live since the last pass — only these animate in.
  final Set<String> _newArrivals = {};

  // Identity memoization: one built ForumPostCard per post id. A card
  // widget is rebuilt only when its post instance changed (the
  // controller replaces post objects whenever their content changes) or
  // a controller-derived flag feeding the card changed (reported / own /
  // editable, post- or reply-level). Keeps one Like tap from rebuilding
  // every visible card. New / deleted / reordered posts still rebuild —
  // cards are always emitted in the current visible order.
  final Map<String, _CachedCard> _cardCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Boot is idempotent: if the controller already started (the normal
    // case) this is a no-op; it also keeps a directly-mounted section
    // working in tests.
    unawaited(widget.forumController.startOnline());
    // Pagination window / seen-id bookkeeping runs here, outside build
    // (fix: these were mutated during build without setState).
    widget.forumController.addListener(_onControllerChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_disposed) {
      // Coming back from the background: retry initialization / Realtime
      // and pull anything posted while the app was asleep.
      unawaited(widget.forumController.retryOnline());
    }
  }

  @override
  void didUpdateWidget(CommunityForumSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.forumController, oldWidget.forumController)) {
      oldWidget.forumController.removeListener(_onControllerChanged);
      widget.forumController.addListener(_onControllerChanged);
      unawaited(widget.forumController.startOnline());
      _cardCache.clear();
      _newArrivals.clear();
      _seenIds.clear();
      _prevTotal = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    widget.forumController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_disposed || !mounted) return;
    final posts = widget.forumController.posts;
    // Keep what the user already sees when live posts arrive at the
    // top: grow the window by the delta so the bottom card isn't
    // pushed out.
    final prevTotal = _prevTotal;
    if (prevTotal != null && posts.length > prevTotal) {
      _visibleCount += posts.length - prevTotal;
    }
    _prevTotal = posts.length;
    if (_visibleCount > posts.length) {
      _visibleCount = posts.length;
    }
    // Animate only live arrivals, never the initial load: the first
    // pass marks everything seen with no animation, so 100 cached posts
    // cost zero AnimationControllers. Deleted ids are pruned so both
    // stay bounded.
    final bool wasFirstBuild = _seenIds.isEmpty;
    final currentIds = posts.map((p) => p.id).toSet();
    if (!wasFirstBuild) {
      _newArrivals.addAll(currentIds.difference(_seenIds));
    }
    _newArrivals.retainAll(currentIds);
    _seenIds.retainAll(currentIds);
    _seenIds.addAll(currentIds);
    _cardCache.removeWhere((id, _) => !currentIds.contains(id));
    setState(() {});
  }

  /// Returns the memoized card for [post], rebuilding it only when the
  /// post instance or a controller-derived flag changed.
  Widget _cardFor(ForumController controller, ForumPost post, {bool isFirst = false}) {
    final reported = controller.isReported(post.id);
    final own = controller.isOwnPost(post.id);
    final canEdit = controller.canEditPost(post.id);
    // Reply-level flags are closures inside the card — fold them into
    // the signature so a reply report / own / edit-window change still
    // rebuilds that card.
    final replySig = StringBuffer();
    for (final r in post.replies) {
      replySig
        ..write(controller.isReported(r.id) ? '1' : '0')
        ..write(controller.isOwnReply(r.id) ? '1' : '0')
        ..write(controller.canEditReply(post.id, r.id) ? '1' : '0');
    }
    final actionsKey = isFirst ? widget.firstPostActionsKey : null;
    final cached = _cardCache[post.id];
    if (cached != null &&
        identical(cached.post, post) &&
        cached.reported == reported &&
        cached.own == own &&
        cached.canEdit == canEdit &&
        cached.replySig == replySig.toString() &&
        cached.actionsKey == actionsKey) {
      return _wrapIfNew(cached.widget, post.id);
    }
    final card = RepaintBoundary(
      child: ForumPostCard(
        key: ValueKey(post.id),
        post: post,
        actionsKey: actionsKey,
        onViewLikers: controller.likerNames,
        onReactionTap: (reactionType) =>
            controller.toggleReaction(post.id, reactionType),
        onReplyReactionTap: (replyId, reactionType) =>
            controller.toggleReplyReaction(
          post.id,
          replyId,
          reactionType,
        ),
        onSendReply: (authorName, message, replyToName) =>
            controller.addReply(
          postId: post.id,
          authorName: authorName,
          message: message,
          replyToName: replyToName,
        ),
        isPostReported: reported,
        isReplyReported: controller.isReported,
        onSubmitReport: (targetId, targetKind, reason, details) =>
            controller.reportTarget(
          targetId: targetId,
          targetKind: targetKind,
          reason: reason,
          details: details,
        ),
        isPostOwn: own,
        canEditPost: canEdit,
        isReplyOwn: controller.isOwnReply,
        canEditReply: (replyId) =>
            controller.canEditReply(post.id, replyId),
        onEditPost: (message) =>
            controller.editPost(postId: post.id, message: message),
        onDeletePost: () => controller.deletePost(post.id),
        onEditReply: (replyId, message) => controller.editReply(
          postId: post.id,
          replyId: replyId,
          message: message,
        ),
        onDeleteReply: (replyId) =>
            controller.deleteReply(postId: post.id, replyId: replyId),
        onRetrySend: () => controller.resendPending(post.id),
        onRetryReplySend: (replyId) =>
            controller.resendPending(replyId),
      ),
    );
    _cardCache[post.id] = _CachedCard(
      post: post,
      widget: card,
      reported: reported,
      own: own,
      canEdit: canEdit,
      replySig: replySig.toString(),
      actionsKey: actionsKey,
    );
    return _wrapIfNew(card, post.id);
  }

  Widget _wrapIfNew(Widget card, String id) {
    if (!_newArrivals.contains(id)) return card;
    return _LiveInsertWrapper(
      key: ValueKey('anim-$id'),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final controller = widget.forumController;
    final posts = controller.posts;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            RevealOnAppear(
              id: 'forum-header',
              index: 1,
              floatUp: true,
              child: _ForumHeader(
                title: lang.t('forum_title'),
                subtitle: lang.t('forum_subtitle'),
                live: controller.isOnline,
                buttonKey: widget.forumHeaderKey,
                onRetry: () async {
                  await controller.retryOnline();
                },
                onShareTap: () {
                  CreatePostDialog.show(context, controller: controller);
                },
              ),
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
                      onPressed: () async {
                        HapticFeedback.lightImpact().catchError((_) {});
                        await controller.retryOnline();
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
              KeyedSubtree(
                key: widget.firstPostActionsKey,
                child: Padding(
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
                ),
              )
            else ...[
              // Paginate: first paint builds max 20 cards, not 100.
              for (final (index, post) in posts.take(_visibleCount).indexed)
                RevealOnAppear(
                  key: ValueKey('reveal-${post.id}'),
                  id: 'forum-post-${post.id}',
                  index: 2 + index,
                  floatUp: true,
                  animate: index < 6,
                  child: _cardFor(controller, post, isFirst: index == 0),
                ),
              if (_visibleCount < posts.length)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact().catchError((_) {});
                      setState(() {
                        _visibleCount += _pageSize;
                      });
                    },
                    icon: const Icon(Icons.expand_more_rounded, size: 16),
                    label: Text(
                      lang.t('forum_show_more',
                          {'remaining': '${posts.length - _visibleCount}'}),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      backgroundColor: Colors.white,
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
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Memoization entry: the last built card widget for a post id plus the
/// inputs that decided it, so unchanged cards are reused as-is.
class _CachedCard {
  final ForumPost post;
  final Widget widget;
  final bool reported;
  final bool own;
  final bool canEdit;
  final String replySig;
  final Key? actionsKey;

  const _CachedCard({
    required this.post,
    required this.widget,
    required this.reported,
    required this.own,
    required this.canEdit,
    required this.replySig,
    this.actionsKey,
  });
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

/// Compact pill showing offline status when viewing cached posts.
/// Tapping retries the connection.
class _OfflineStatusPill extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineStatusPill({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact().catchError((_) {});
            onRetry();
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1E4D6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFE3C9AE),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 14,
                  color: Color(0xFF8C7267),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Offline • showing saved — tap to retry',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8C7267),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  final Key? buttonKey;

  const _ForumHeader({
    required this.title,
    required this.subtitle,
    required this.live,
    required this.onRetry,
    required this.onShareTap,
    this.buttonKey,
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
        // Row 1: title and refresh
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  shadows: [
                    Shadow(
                      color: Color(0x99FFF4E6),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                tooltip: lang.t('forum_refresh'),
                onPressed: () {
                  HapticFeedback.lightImpact().catchError((_) {});
                  onRetry();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.warmMid,
                  shadows: [
                    Shadow(
                      color: Color(0x99FFF4E6),
                      blurRadius: 4,
                    ),
                  ],
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        // Row 2: status chip (only when offline or showing saved data)
        if (!live) ...[
          const SizedBox(height: 6),
          _OfflineStatusPill(onRetry: onRetry),
        ],
        // Row 3: visibility note
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.public_outlined,
              size: 14,
              color: AppColors.muted,
              shadows: [
                Shadow(
                  color: Color(0x99FFF4E6),
                  blurRadius: 4,
                ),
              ],
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
                  shadows: [
                    Shadow(
                      color: Color(0x99FFF4E6),
                      blurRadius: 4,
                    ),
                  ],
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
        const SizedBox(height: 12),
        KeyedSubtree(
          key: buttonKey,
          child: SizedBox(
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
        ),
      ],
    );
  }
}
