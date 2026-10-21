import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/data/guide/guide_repository.dart';
import 'package:nita/views/condolences/candle_section.dart';
import 'package:nita/views/condolences/forum/community_forum_section.dart';
import 'package:nita/views/guide/guide_page.dart';

/// The Pakikiramay (condolences) tab: the visitor lights a virtual candle
/// in Nanay's memory, and can share and read memories, condolences, and
/// reflections on loss in the community forum.
class CondolencesPage extends StatefulWidget {
  final ScrollController? controller;

  /// Reports the active tab index from the home shell, so the guide knows
  /// when the Condolences tab (4) is actually open.
  final ValueNotifier<int>? activeTab;

  /// Bumped by the shell's top-bar `?` to replay the Condolences guide.
  final ValueListenable<int>? guideRequests;

  /// Candle controller, owned by the home shell (composition root)
  /// and injected here.
  final CondolencesController condolencesController;

  /// Optional forum controller. If null, a local instance is created.
  final ForumController? forumController;

  const CondolencesPage({
    super.key,
    this.controller,
    this.activeTab,
    this.guideRequests,
    required this.condolencesController,
    this.forumController,
  });

  @override
  State<CondolencesPage> createState() => _CondolencesPageState();
}

class _CondolencesPageState extends State<CondolencesPage> {
  static const int _condolencesTab = 4;

  late final ForumController _forumController;
  late final bool _ownsController;

  final GlobalKey _privateMessageKey = GlobalKey();
  final GlobalKey _forumHeaderKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();

  final ValueNotifier<Rect?> _privateMessageRect = ValueNotifier<Rect?>(null);
  final ValueNotifier<Rect?> _forumHeaderRect = ValueNotifier<Rect?>(null);
  final ValueNotifier<Rect?> _actionsRect = ValueNotifier<Rect?>(null);

  bool _guideCheckStarted = false;
  bool _guideOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.forumController != null) {
      _forumController = widget.forumController!;
      _ownsController = false;
    } else {
      _forumController = ForumController();
      _ownsController = true;
    }
    widget.activeTab?.addListener(_onActiveTabChanged);
    widget.guideRequests?.addListener(_onGuideRequested);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowCondolencesGuide(),
    );
  }

  @override
  void didUpdateWidget(covariant CondolencesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeTab, widget.activeTab)) {
      oldWidget.activeTab?.removeListener(_onActiveTabChanged);
      widget.activeTab?.addListener(_onActiveTabChanged);
    }
    if (!identical(oldWidget.guideRequests, widget.guideRequests)) {
      oldWidget.guideRequests?.removeListener(_onGuideRequested);
      widget.guideRequests?.addListener(_onGuideRequested);
    }
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onActiveTabChanged);
    widget.guideRequests?.removeListener(_onGuideRequested);
    _privateMessageRect.dispose();
    _forumHeaderRect.dispose();
    _actionsRect.dispose();
    if (_ownsController) {
      _forumController.dispose();
    }
    super.dispose();
  }

  void _onActiveTabChanged() {
    if (widget.activeTab?.value == _condolencesTab) {
      _maybeShowCondolencesGuide();
    }
  }

  void _onGuideRequested() => _maybeShowCondolencesGuide(replay: true);

  void _maybeShowCondolencesGuide({bool replay = false}) {
    if (_guideOpen) return;
    if (!replay && _guideCheckStarted) return;
    if (widget.activeTab?.value != _condolencesTab) return;
    _guideCheckStarted = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openCondolencesGuide(replay: replay),
    );
    WidgetsBinding.instance.scheduleFrame();
  }

  Rect? _rectOnScreen(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.top < 0 || rect.bottom > screen.height) return null;
    return rect;
  }

  Future<void> _revealPrivateMessage() async {
    final scrollController = widget.controller;
    if (scrollController != null &&
        scrollController.hasClients &&
        scrollController.position.pixels > 0) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    _privateMessageRect.value = _privateMessageRectOnScreen();
  }

  Future<void> _revealForumHeader() async {
    final ctx = _forumHeaderKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    _forumHeaderRect.value = _forumButtonRectOnScreen();
  }

  Future<void> _revealActions() async {
    final ctx = _actionsKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.15,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    _actionsRect.value = _actionsRectOnScreen();
  }

  Rect? _privateMessageRectOnScreen() {
    final raw = _rectOnScreen(_privateMessageKey);
    if (raw == null) return null;
    return Rect.fromLTRB(
      raw.left - 8,
      raw.top - 5,
      raw.right + 8,
      raw.bottom + 5,
    );
  }

  Rect? _forumButtonRectOnScreen() {
    final raw = _rectOnScreen(_forumHeaderKey);
    if (raw == null) return null;
    return Rect.fromLTRB(
      raw.left - 8,
      raw.top - 5,
      raw.right + 8,
      raw.bottom + 5,
    );
  }

  Rect? _actionsRectOnScreen() {
    final raw = _rectOnScreen(_actionsKey);
    if (raw == null) return null;
    return Rect.fromLTRB(
      raw.left - 14,
      raw.top - 4,
      raw.right + 14,
      raw.bottom + 4,
    );
  }

  Future<void> _openCondolencesGuide({bool replay = false}) async {
    if (!mounted || _guideOpen || widget.activeTab?.value != _condolencesTab) {
      return;
    }

    if (!replay) {
      final seen = await const GuideRepository.condolences().hasSeen();
      if (!mounted || seen || widget.activeTab?.value != _condolencesTab) return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      if (!replay) _guideCheckStarted = false;
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _guideOpen || widget.activeTab?.value != _condolencesTab) {
      return;
    }

    final scrollController = widget.controller;
    if (scrollController != null &&
        scrollController.hasClients &&
        scrollController.position.pixels > 0) {
      scrollController.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _guideOpen || widget.activeTab?.value != _condolencesTab) {
        return;
      }
    }

    var rect = _privateMessageRectOnScreen();
    for (var i = 0; i < 6 && rect == null; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _guideOpen || widget.activeTab?.value != _condolencesTab) {
        return;
      }
      rect = _privateMessageRectOnScreen();
    }
    _privateMessageRect.value = rect;

    _guideOpen = true;
    if (!mounted) return;
    Navigator.of(context)
        .push(
          fadeRoute(
            GuidePage(
              tour: GuideTour.condolences,
              condolencesPrivateMessageRect: _privateMessageRect,
              condolencesForumHeaderRect: _forumHeaderRect,
              condolencesActionsRect: _actionsRect,
              onCondolencesPrivateMessageShown: _revealPrivateMessage,
              onCondolencesForumHeaderShown: _revealForumHeader,
              onCondolencesActionsShown: _revealActions,
            ),
            opaque: false,
          ),
        )
        .then((_) {
          if (!mounted) return;
          _guideOpen = false;
        });
  }

  /// Pull-to-refresh / refresh-button path: reloads the forum feed and
  /// re-opens realtime so elderly users can force the latest messages.
  Future<void> _handleRefresh() async {
    await _forumController.loadPosts();
    try {
      await _forumController.subscribeRealtime();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.warmDark,
      child: CustomScrollView(
        controller: widget.controller,
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: _PakikiramayHeader(
                title: lang.t('nav_condolences'),
                subtitle: lang.t('condolences_subtitle'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CandleSection(
                  condolencesController: widget.condolencesController,
                  privateMessageKey: _privateMessageKey,
                ),
                const SizedBox(height: 28),
                CommunityForumSection(
                  forumController: _forumController,
                  forumHeaderKey: _forumHeaderKey,
                  firstPostActionsKey: _actionsKey,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pakikiramay title matching the reference image: large Inter bold
/// dark-brown title, warm subtitle, and a line–sprig–line gold divider.
/// Local to this tab so Words/Gallery headers stay untouched.
class _PakikiramayHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PakikiramayHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.warmMid,
          ),
        ),
        const SizedBox(height: 10),
        const _LeafDivider(),
      ],
    );
  }
}

/// Line–sprig–line divider: two hairlines with a tiny three-leaf
/// gold sprig in the middle, like the reference image.
class _LeafDivider extends StatelessWidget {
  const _LeafDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 10),
        CustomPaint(
          size: const Size(26, 16),
          painter: _SprigPainter(),
        ),
        const SizedBox(width: 10),
        Container(
          width: 72,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.45),
        ),
      ],
    );
  }
}

class _SprigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold;
    final cx = size.width / 2;
    final baseY = size.height - 1;
    // Stem.
    canvas.drawLine(
      Offset(cx, baseY),
      Offset(cx, 3),
      paint..strokeWidth = 1.2,
    );
    // Three leaves: top + left + right.
    _leaf(canvas, Offset(cx, 5), 0, paint);
    _leaf(canvas, Offset(cx - 1, 9), -0.7, paint);
    _leaf(canvas, Offset(cx + 1, 9), 0.7, paint);
  }

  void _leaf(Canvas canvas, Offset at, double angle, Paint paint) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      const Rect.fromLTWH(-2.2, -4.5, 4.4, 9),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
