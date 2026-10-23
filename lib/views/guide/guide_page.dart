import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/guide_art_precache.dart';
import 'package:nita/core/utils/motion.dart';
import 'package:nita/data/guide/guide_repository.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/guide/guide_content.dart';
import 'package:nita/widgets/abuloy_touch.dart';
import 'package:nita/widgets/app_bottom_nav.dart';
import 'package:nita/widgets/app_brand_bar.dart';

/// Which tour a [GuidePage] runs.
enum GuideTour {
  /// Homepage: top bar, Abuloy touch, bottom navigation.
  home,

  /// Gallery: the search bar, then the filter pills.
  gallery,

  /// Family: a single hint pointing at a member card.
  family,

  /// Words (Mga Salita): a single hint pointing at the filter pills.
  words,

  /// Condolences (Pakikiramay): private message, community stories, and reply/react.
  condolences,
}

/// First-visit "spotlight" guide: the app is dimmed, one real part stays lit,
/// and Nanay explains it in a speech bubble.
///
/// Homepage tour (three stops):
///   1. Top bar — language switch and Settings.
///   2. Abuloy touch — the floating gift button.
///   3. Bottom nav — the five tabs.
///
/// Gallery tour (three stops):
///   1. The search bar — type to narrow the photo grid.
///   2. The filter pills — categories plus the candle-gated Huling Araw row.
///   3. The featured card — tap to play the photos as a slideshow with music.
///
/// Family tour (one stop):
///   1. A member card — tap any card to read that person's details.
///
/// The real controls stay lit through a cut-out in the scrim.
///
/// Shown once automatically (see `HomePage` and `GalleryGridView`), and the
/// homepage tour is always reachable again from the top-bar `?` and Settings.
/// Closing it by any route — the last button, Skip, or the system back
/// gesture — marks that tour seen, so it never nags twice.
///
/// Accessibility: large type, 56px buttons with visible labels, high contrast
/// against the scrim, no autoplay or timers, and the lit app fragments are
/// hidden from screen readers because the bubble already names them.
class GuidePage extends StatefulWidget {
  /// Which tour to show. Defaults to the homepage tour so existing callers
  /// (Settings, the top-bar `?`) keep working unchanged.
  final GuideTour tour;

  /// Global rect of the Gallery search bar, lit by the first Gallery stop.
  final Rect? searchBarRect;

  /// Global rect of the Gallery filter-pill row, lit by the second stop.
  final Rect? filterPillsRect;

  /// Called when the filter-pills stop becomes visible, so the Gallery can
  /// scroll the row to the gold Huling Araw pill. Optional: the direct-widget
  /// tests and any future non-Gallery use can omit it.
  final VoidCallback? onFilterPillsShown;

  /// Global rect of the gold Huling Araw pill, published by the Gallery once
  /// its row has finished sliding. The pills stop rings it inside the lit row
  /// so the copy's "this gold pill" has something to point at.
  final ValueListenable<Rect?>? hulingArawRect;

  /// Called when the featured-slideshow stop becomes visible, so the Gallery
  /// can scroll the card on screen (short viewports) before it is lit.
  final VoidCallback? onFeaturedCardShown;

  /// Global rect of the featured slideshow card. A listenable because the
  /// Gallery may have to scroll the card into view after the stop opens; the
  /// hole follows as soon as the new position is measured.
  final ValueListenable<Rect?>? featuredCardRect;

  /// Global rect of the Family member card the tour points at. A listenable
  /// because the page scrolls the card on screen before lighting it, and keeps
  /// the hole glued to it if the list moves while the guide is open.
  final ValueListenable<Rect?>? familyMemberRect;

  /// Global rect of the Words filter-pill row the tour points at.
  final ValueListenable<Rect?>? wordsFilterPillsRect;

  /// Global rect of the Condolences private message area.
  final ValueListenable<Rect?>? condolencesPrivateMessageRect;

  /// Global rect of the Condolences community forum header / share button.
  final ValueListenable<Rect?>? condolencesForumHeaderRect;

  /// Global rect of the Condolences reaction and reply action row.
  final ValueListenable<Rect?>? condolencesActionsRect;

  /// Callbacks when stops become visible so CondolencesPage can scroll to them.
  final VoidCallback? onCondolencesPrivateMessageShown;
  final VoidCallback? onCondolencesForumHeaderShown;
  final VoidCallback? onCondolencesActionsShown;

  const GuidePage({
    super.key,
    this.tour = GuideTour.home,
    this.searchBarRect,
    this.filterPillsRect,
    this.onFilterPillsShown,
    this.hulingArawRect,
    this.onFeaturedCardShown,
    this.featuredCardRect,
    this.familyMemberRect,
    this.wordsFilterPillsRect,
    this.condolencesPrivateMessageRect,
    this.condolencesForumHeaderRect,
    this.condolencesActionsRect,
    this.onCondolencesPrivateMessageShown,
    this.onCondolencesForumHeaderShown,
    this.onCondolencesActionsShown,
  });

  /// Which tour the shared top-bar `?` should replay while tab [tab] is
  /// active. The Gallery and Family tabs have their own tours; every other
  /// tab keeps the homepage tour, so the button always does something useful.
  static GuideTour tourForTab(int tab) => switch (tab) {
    1 => GuideTour.gallery,
    2 => GuideTour.family,
    _ => GuideTour.home,
  };

  /// The dimming layer over the app. Deliberately translucent: the visitor
  /// should still recognise Home underneath, not stare at a black screen.
  static const double scrimOpacity = 0.85;
  static const Key scrimKey = Key('guide-scrim');
  static const Key spotlightScrimKey = Key('guide-spotlight-scrim');
  static const Key gallerySearchOutlineKey = Key(
    'guide-gallery-search-outline',
  );
  static const Key galleryPillsOutlineKey = Key('guide-gallery-pills-outline');
  static const Key galleryHulingArawOutlineKey = Key(
    'guide-gallery-huling-araw-outline',
  );
  static const Key galleryFeaturedOutlineKey = Key(
    'guide-gallery-featured-outline',
  );
  static const Key familyMemberOutlineKey = Key('guide-family-member-outline');
  static const Key wordsPillsOutlineKey = Key('guide-words-pills-outline');
  static const Key condolencesPrivateMessageOutlineKey = Key(
    'guide-condolences-private-message-outline',
  );
  static const Key condolencesForumHeaderOutlineKey = Key(
    'guide-condolences-forum-header-outline',
  );
  static const Key condolencesActionsOutlineKey = Key(
    'guide-condolences-actions-outline',
  );

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  /// The tour-specific flag. The Gallery, Family, and Words tips have their
  /// own keys, so a visitor who finished the homepage tour still sees them.
  GuideRepository get _repo => switch (widget.tour) {
    GuideTour.gallery => const GuideRepository.gallery(),
    GuideTour.family => const GuideRepository.family(),
    GuideTour.words => const GuideRepository.words(),
    GuideTour.condolences => const GuideRepository.condolences(),
    GuideTour.home => const GuideRepository(),
  };

  List<GuideStep> get _steps => switch (widget.tour) {
    GuideTour.gallery => galleryGuideSteps,
    GuideTour.family => familyGuideSteps,
    GuideTour.words => wordsGuideSteps,
    GuideTour.condolences => condolencesGuideSteps,
    GuideTour.home => guideSteps,
  };

  final VisitorRepository _visitorRepo = const VisitorRepository();
  GuideController? _guideController;
  bool _guideOpenScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _guideController = context.read<GuideController>();
    if (!_guideOpenScheduled) {
      _guideOpenScheduled = true;
      // Do not notify provider listeners during the route's first build; that
      // would ask the provider scope to rebuild in the middle of this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _finishing) return;
        _guideController?.isGuideOpen = true;
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  @override
  void dispose() {
    _guideController?.isGuideOpen = false;
    super.dispose();
  }

  int _step = 0;

  /// Null while loading, '' when there is no stored visitor, otherwise the
  /// first name used in the top bar greeting.
  String? _firstName;

  @override
  void initState() {
    super.initState();
    // Only the homepage top-bar stop prints the visitor's greeting.
    if (widget.tour == GuideTour.home) _loadVisitorName();
  }

  Future<void> _loadVisitorName() async {
    String first = '';
    try {
      final full = await _visitorRepo.localName();
      first = VisitorRepository.firstName(full);
    } catch (_) {
      // Prefs unreadable — the bar falls back to the brand-only layout.
      first = '';
    }
    if (!mounted) return;
    setState(() => _firstName = first);
  }

  void _advance() {
    if (_step >= _steps.length - 1) {
      _close();
      return;
    }
    _goToStep(_step + 1);
  }

  /// Moves to [next] and lets the host page react to the new stop. Keeping
  /// this in one place means back-navigation (and future stops) triggers the
  /// same reveal as Next.
  void _goToStep(int next) {
    setState(() => _step = next);
    _notifyStepShown(next);
  }

  /// Tells the host page which stop just became visible, so it can scroll a
  /// row or reveal a card before it is lit.
  void _notifyStepShown(int index) {
    final spotlight = _steps[index].spotlight;
    switch (spotlight) {
      case GuideSpotlight.galleryFilterPills:
        widget.onFilterPillsShown?.call();
      case GuideSpotlight.galleryFeaturedCard:
        widget.onFeaturedCardShown?.call();
      case GuideSpotlight.condolencesPrivateMessage:
        widget.onCondolencesPrivateMessageShown?.call();
      case GuideSpotlight.condolencesCommunityForum:
        widget.onCondolencesForumHeaderShown?.call();
      case GuideSpotlight.condolencesReplyReact:
        widget.onCondolencesActionsShown?.call();
      default:
        break;
    }
  }

  /// True once the shared finish path has started, so a double tap cannot
  /// pop the page underneath while the guide route is fading out.
  bool _finishing = false;

  /// Maps the tour to the active shell tab id. The Words and Condolences tabs
  /// still use their original shell ids (`tribute`, `favorites`).
  String get _tabId => switch (widget.tour) {
    GuideTour.home => 'home',
    GuideTour.gallery => 'gallery',
    GuideTour.family => 'family',
    GuideTour.words => 'tribute',
    GuideTour.condolences => 'favorites',
  };

  /// One exit path for Done, Skip, system back, and an external route pop.
  ///
  /// The repository flag stays tour-scoped, while [GuideController] owns the
  /// seen state and the scroll back to the top so every tab behaves the same.
  void _finishGuide({bool closeRoute = true}) {
    if (_finishing) return;
    _finishing = true;

    _repo.markSeen();

    final controller = _guideController;
    if (controller == null) {
      if (closeRoute) _popGuideRoute();
      return;
    }

    controller.onGuideFinished(
      _tabId,
      closeOverlay: closeRoute ? _popGuideRoute : null,
    );
  }

  void _popGuideRoute() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  /// Persist first, then pop. `markSeen` swallows its own errors, so this
  /// never leaves the visitor stuck on a dead button.
  void _close() => _finishGuide();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final steps = _steps;
    final step = steps[_step];
    final isLast = _step == steps.length - 1;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final stepLabel = lang.t('guide_step', {
      'current': '${_step + 1}',
      'total': '${steps.length}',
    });
    // Each tab tour has its own closing label — "Start exploring" reads
    // oddly after a couple of in-tour hints.
    final doneKey = switch (widget.tour) {
      GuideTour.gallery => 'gallery_guide_done',
      GuideTour.family => 'family_guide_done',
      GuideTour.words => 'words_guide_done',
      GuideTour.condolences => 'condolences_guide_done',
      GuideTour.home => 'guide_done',
    };

    final first = _firstName ?? '';
    final greeting = first.isNotEmpty
        ? lang.t('header_greeting', {'name': first})
        : null;

    Widget buildDialogue({
      double? maxHeight,
      double? artHeight,
      bool showArt = true,
      bool showTopConnector = false,
    }) => _Dialogue(
      art: step.art,
      title: lang.t(step.titleKey),
      body: lang.t(step.bodyKey),
      nextLabel: isLast ? lang.t(doneKey) : lang.t('guide_next'),
      onNext: isLast ? _close : _advance,
      onBack: _step > 0 ? () => _goToStep(_step - 1) : null,
      skipLabel: lang.t('guide_skip'),
      onSkip: _close,
      compact: compact,
      maxHeight: maxHeight,
      artHeight: artHeight,
      showArt: showArt,
      showTopConnector: showTopConnector,
      stepCount: steps.length,
      activeStep: _step,
      stepLabel: stepLabel,
    );

    final Widget body;
    if (widget.tour == GuideTour.gallery) {
      final isSearch = step.spotlight == GuideSpotlight.gallerySearchBar;
      final isPills = step.spotlight == GuideSpotlight.galleryFilterPills;
      final isFeatured = step.spotlight == GuideSpotlight.galleryFeaturedCard;
      final outlineKey = isSearch
          ? GuidePage.gallerySearchOutlineKey
          : isPills
          ? GuidePage.galleryPillsOutlineKey
          : GuidePage.galleryFeaturedOutlineKey;

      // Blocks the dimmed Gallery underneath from the screen reader while the
      // bubble is talking; the lit control stays visible but inert.
      Widget cutout(Rect? rect) => BlockSemantics(
        child: _CutoutStep(
          rect: rect,
          outlineKey: outlineKey,
          holeRadius: isSearch ? 16 : (isPills ? 16 : 20),
          outlineRadius: isSearch ? 20 : (isPills ? 18 : 22),
          art: step.art,
          dialogueBuilder: buildDialogue,
          skipLabel: lang.t('guide_skip'),
          onSkip: _close,
          stepLabel: stepLabel,
          stepCount: steps.length,
          activeStep: _step,
          // The gold pill the pills copy names, ringed once the row has
          // finished sliding it into view.
          extraHighlight: isPills ? widget.hulingArawRect : null,
          extraHighlightKey: GuidePage.galleryHulingArawOutlineKey,
        ),
      );

      final featuredRect = widget.featuredCardRect;
      if (isFeatured && featuredRect != null) {
        // The card may slide into view after the stop opens, so the hole
        // follows the latest measured rect instead of the push-time one.
        body = ValueListenableBuilder<Rect?>(
          valueListenable: featuredRect,
          builder: (context, rect, _) => cutout(rect),
        );
      } else {
        body = cutout(
          isSearch
              ? widget.searchBarRect
              : isPills
              ? widget.filterPillsRect
              : null,
        );
      }
    } else if (widget.tour == GuideTour.family) {
      // One stop: light a member card. The page scrolls it on screen and
      // publishes its rect before opening; the hole follows any later move.
      Widget cutout(Rect? rect) => BlockSemantics(
        child: _CutoutStep(
          rect: rect,
          outlineKey: GuidePage.familyMemberOutlineKey,
          holeRadius: 18,
          outlineRadius: 20,
          art: step.art,
          dialogueBuilder: buildDialogue,
          skipLabel: lang.t('guide_skip'),
          onSkip: _close,
          stepLabel: stepLabel,
          stepCount: steps.length,
          activeStep: _step,
        ),
      );

      final memberRect = widget.familyMemberRect;
      body = memberRect == null
          ? cutout(null)
          : ValueListenableBuilder<Rect?>(
              valueListenable: memberRect,
              builder: (context, rect, _) => cutout(rect),
            );
    } else if (widget.tour == GuideTour.words) {
      Widget cutout(Rect? rect) => BlockSemantics(
        child: _CutoutStep(
          rect: rect,
          outlineKey: GuidePage.wordsPillsOutlineKey,
          holeRadius: 16,
          outlineRadius: 18,
          art: step.art,
          dialogueBuilder: buildDialogue,
          skipLabel: lang.t('guide_skip'),
          onSkip: _close,
          stepLabel: stepLabel,
          stepCount: steps.length,
          activeStep: _step,
        ),
      );

      final pillsRect = widget.wordsFilterPillsRect;
      body = pillsRect == null
          ? cutout(null)
          : ValueListenableBuilder<Rect?>(
              valueListenable: pillsRect,
              builder: (context, rect, _) => cutout(rect),
            );
    } else if (widget.tour == GuideTour.condolences) {
      final isPrivate =
          step.spotlight == GuideSpotlight.condolencesPrivateMessage;
      final isForum =
          step.spotlight == GuideSpotlight.condolencesCommunityForum;
      final outlineKey = isPrivate
          ? GuidePage.condolencesPrivateMessageOutlineKey
          : isForum
          ? GuidePage.condolencesForumHeaderOutlineKey
          : GuidePage.condolencesActionsOutlineKey;
      final listenable = isPrivate
          ? widget.condolencesPrivateMessageRect
          : isForum
          ? widget.condolencesForumHeaderRect
          : widget.condolencesActionsRect;

      Widget cutout(Rect? rect) => BlockSemantics(
        child: _CutoutStep(
          rect: rect,
          outlineKey: outlineKey,
          holeRadius: step.spotlight == GuideSpotlight.condolencesReplyReact
              ? 8
              : 16,
          outlineRadius: step.spotlight == GuideSpotlight.condolencesReplyReact
              ? 12
              : 20,
          art: step.art,
          dialogueBuilder: buildDialogue,
          skipLabel: lang.t('guide_skip'),
          onSkip: _close,
          stepLabel: stepLabel,
          stepCount: steps.length,
          activeStep: _step,
        ),
      );

      body = listenable == null
          ? cutout(null)
          : ValueListenableBuilder<Rect?>(
              valueListenable: listenable,
              builder: (context, rect, _) => cutout(rect),
            );
    } else {
      body = Stack(
        // Stretch every child to the route's full size so the dim layer can
        // never take its size from the bubble above it.
        fit: StackFit.expand,
        children: [
          ColoredBox(
            key: GuidePage.scrimKey,
            color: AppColors.charcoal.withValues(alpha: GuidePage.scrimOpacity),
          ),
          switch (step.spotlight) {
            GuideSpotlight.topBar => _TopBarStep(
              art: step.art,
              greeting: greeting,
              helpTooltip: lang.t('guide_help_tooltip'),
              dialogueBuilder: buildDialogue,
              skipLabel: lang.t('guide_skip'),
              onSkip: _close,
              stepLabel: stepLabel,
              stepCount: steps.length,
              activeStep: _step,
            ),
            GuideSpotlight.abuloy => _AbuloyStep(
              art: step.art,
              dialogueBuilder: buildDialogue,
              skipLabel: lang.t('guide_skip'),
              onSkip: _close,
              stepLabel: stepLabel,
              stepCount: steps.length,
              activeStep: _step,
            ),
            GuideSpotlight.bottomNav => _NavStep(
              art: step.art,
              dialogueBuilder: buildDialogue,
              skipLabel: lang.t('guide_skip'),
              onSkip: _close,
              stepLabel: stepLabel,
              stepCount: steps.length,
              activeStep: _step,
            ),
            // Gallery, Family, and Words stops never appear inside the homepage
            // tour; those tours are built above, with their own cut-out scrim.
            GuideSpotlight.gallerySearchBar ||
            GuideSpotlight.galleryFilterPills ||
            GuideSpotlight.galleryFeaturedCard ||
            GuideSpotlight.familyMember ||
            GuideSpotlight.wordsFilterPills ||
            GuideSpotlight.condolencesPrivateMessage ||
            GuideSpotlight.condolencesCommunityForum ||
            GuideSpotlight.condolencesReplyReact => const SizedBox.shrink(),
          },
        ],
      );
    }

    return PopScope(
      // Back goes to the previous stop; on the first stop it uses the same
      // finish path as Done and Skip.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // Some other route owner popped us. Mark/scroll, but do not pop
          // again from this already-disposed route.
          _finishGuide(closeRoute: false);
        } else if (_step > 0) {
          _goToStep(_step - 1);
        } else {
          _finishGuide();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.charcoal,
        ),
        // Transparent so the route below (Home, Settings, or Gallery) shows
        // through the scrim. The route itself is pushed with `opaque: false`.
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Keep the dim layer edge to edge. With the default `true`, any
          // bottom inset (an on-screen keyboard, for instance) would shrink
          // the body and leave a bright strip of the app undimmed.
          resizeToAvoidBottomInset: false,
          body: body,
        ),
      ),
    );
  }
}

/// Short-viewport (landscape phone) layout: Nanay, Skip, and the progress
/// dots sit in a left rail; the bubble uses the remaining width and full
/// height. The bubble's body scrolls inside a capped card when needed, so the
/// 56px Next button never falls below the viewport.
class _LandscapeLayout extends StatelessWidget {
  final GuideArt art;
  final _DialogueBuilder dialogueBuilder;
  final String skipLabel;
  final VoidCallback onSkip;
  final String stepLabel;
  final int stepCount;
  final int activeStep;

  /// Space reserved on the right for the lit Abuloy coin.
  final double rightInset;

  const _LandscapeLayout({
    required this.art,
    required this.dialogueBuilder,
    required this.skipLabel,
    required this.onSkip,
    required this.stepLabel,
    required this.stepCount,
    required this.activeStep,
    this.rightInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final railWidth = (width * 0.28).clamp(120.0, 185.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20 + rightInset, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railWidth,
            child: Column(
              children: [
                Expanded(
                  // Expand the box before the asset decodes; otherwise a
                  // not-yet-loaded Image reports zero intrinsic width and the
                  // figure vanishes.
                  child: SizedBox.expand(
                    child: ExcludeSemantics(
                      child: _AliveVector(art: art, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: dialogueBuilder(showArt: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-bar stop: the real brand bar stays lit at the very top, and Nanay's
/// bubble sits immediately below it. The rest of the screen shows the dimmed
/// app, with the real nav still visible but not spotlighted.
class _TopBarStep extends StatelessWidget {
  final GuideArt art;
  final String? greeting;
  final String helpTooltip;
  final _DialogueBuilder dialogueBuilder;
  final String skipLabel;
  final VoidCallback onSkip;
  final String stepLabel;
  final int stepCount;
  final int activeStep;

  const _TopBarStep({
    required this.art,
    required this.greeting,
    required this.helpTooltip,
    required this.dialogueBuilder,
    required this.skipLabel,
    required this.onSkip,
    required this.stepLabel,
    required this.stepCount,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 500;

    return Column(
      children: [
        // Outside SafeArea on purpose: AppBrandBar applies the status-bar
        // inset itself, exactly like it does on Home.
        _LitTopBar(greeting: greeting, helpTooltip: helpTooltip),
        Expanded(
          child: SafeArea(
            top: false,
            child: short
                ? _LandscapeLayout(
                    art: art,
                    dialogueBuilder: dialogueBuilder,
                    skipLabel: skipLabel,
                    onSkip: onSkip,
                    stepLabel: stepLabel,
                    stepCount: stepCount,
                    activeStep: activeStep,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: dialogueBuilder(showTopConnector: true),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Abuloy stop: the floating coin stays lit at its real dock — next to
/// Nanay's portrait — while Nanay's bubble sits beneath it with an arrow.
class _AbuloyStep extends StatelessWidget {
  final GuideArt art;
  final _DialogueBuilder dialogueBuilder;
  final String skipLabel;
  final VoidCallback onSkip;
  final String stepLabel;
  final int stepCount;
  final int activeStep;

  const _AbuloyStep({
    required this.art,
    required this.dialogueBuilder,
    required this.skipLabel,
    required this.onSkip,
    required this.stepLabel,
    required this.stepCount,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final short = size.height < 500;
    // Same dock as the live touch: next to Nanay's portrait on the right.
    // The ring is 8px larger than the 60px coin on every side, so shifting
    // it up by 8px leaves the coin itself on the docked spot.
    final ringTop = AbuloyTouch.dockTopFor(size) - 8;
    // A touch higher than the coin's bottom edge: the bubble and Nanay read as
    // one group under the touch without crowding the hero copy behind them.
    final dialogueTop = math.max(
      0.0,
      ringTop - padding.top + _HighlightedAbuloy.ringSize - 4,
    );

    return Stack(
      children: [
        if (short)
          Positioned.fill(
            child: SafeArea(
              child: _LandscapeLayout(
                art: art,
                dialogueBuilder: dialogueBuilder,
                skipLabel: skipLabel,
                onSkip: onSkip,
                stepLabel: stepLabel,
                stepCount: stepCount,
                activeStep: activeStep,
                // Leave the right edge to the lit coin.
                rightInset: _HighlightedAbuloy.ringSize + 8,
              ),
            ),
          )
        else
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, dialogueTop, 20, 16),
              child: Align(
                alignment: Alignment.topCenter,
                child: dialogueBuilder(),
              ),
            ),
          ),
        Positioned(
          right: 20 - 8,
          top: ringTop,
          width: _HighlightedAbuloy.ringSize,
          height: _HighlightedAbuloy.ringSize,
          child: const _HighlightedAbuloy(),
        ),
        if (!short)
          Positioned(
            right: 36,
            top: ringTop + _HighlightedAbuloy.ringSize + 4,
            child: const _TourBouncingArrow(pointingUp: true),
          ),
      ],
    );
  }
}

/// The same coin the app floats on every tab. Inert: the bubble's Next button
/// moves the tour on.
class _HighlightedAbuloy extends StatelessWidget {
  /// Ring diameter: the 60px [AbuloyTouchVisual] plus 8px breathing room.
  static const double ringSize = AbuloyTouch.size + 16;

  const _HighlightedAbuloy();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft gold lift so the coin reads as the spotlight target.
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.glowGold.withValues(alpha: 0.22),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const AbuloyTouchVisual(),
            // Same gold dashed outline as the Gallery spotlight.
            const Positioned.fill(
              child: CustomPaint(
                painter: _DashedRoundedBorderPainter(
                  color: AppColors.gold,
                  radius: ringSize / 2,
                  strokeWidth: 2,
                  dash: 6,
                  gap: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav stop: Nanay's bubble sits just above the lit nav, exactly like the
/// first version of the spotlight.
class _NavStep extends StatelessWidget {
  final GuideArt art;
  final _DialogueBuilder dialogueBuilder;
  final String skipLabel;
  final VoidCallback onSkip;
  final String stepLabel;
  final int stepCount;
  final int activeStep;

  const _NavStep({
    required this.art,
    required this.dialogueBuilder,
    required this.skipLabel,
    required this.onSkip,
    required this.stepLabel,
    required this.stepCount,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 500;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: short
                ? _LandscapeLayout(
                    art: art,
                    dialogueBuilder: dialogueBuilder,
                    skipLabel: skipLabel,
                    onSkip: onSkip,
                    stepLabel: stepLabel,
                    stepCount: stepCount,
                    activeStep: activeStep,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 24),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: dialogueBuilder(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!short) ...[const _NavGuideArrow(), const SizedBox(height: 8)],
          const _HighlightedNav(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Gallery stop: a hole is cut in the scrim over one real control (the search
/// field or the filter-pill row), so it stays at full brightness while
/// everything else dims. Nanay's bubble sits just below it, with a small
/// arrow pointing back up.
class _CutoutStep extends StatelessWidget {
  /// Measured global rect of the control. Null only if the caller failed to
  /// measure it; the fallback still explains the step, just without the lit
  /// cut-out.
  final Rect? rect;

  /// Identifies the cutout target so each stop has its own test key.
  final Key outlineKey;

  /// Corner radius of the hole (matching the real control).
  final double holeRadius;

  /// Corner radius of the dashed ring drawn just outside the hole. It should
  /// echo the control's rounded corners rather than the hole's exact radius.
  final double outlineRadius;

  /// A second control inside the lit area (the gold Huling Araw pill). Its
  /// rect arrives after the Gallery slides the row into place.
  final ValueListenable<Rect?>? extraHighlight;
  final Key? extraHighlightKey;

  final GuideArt art;
  final _DialogueBuilder dialogueBuilder;
  final String skipLabel;
  final VoidCallback onSkip;
  final String stepLabel;
  final int stepCount;
  final int activeStep;

  const _CutoutStep({
    required this.rect,
    required this.outlineKey,
    required this.art,
    required this.dialogueBuilder,
    required this.skipLabel,
    required this.onSkip,
    required this.stepLabel,
    required this.stepCount,
    required this.activeStep,
    this.holeRadius = 14,
    this.outlineRadius = 20,
    this.extraHighlight,
    this.extraHighlightKey,
  });

  /// The smallest bubble box that still fits a title, the 56px action, and
  /// the dense gaps. Below this the whole dialogue scrolls instead.
  static const double _minDialogueHeight = 120;

  @override
  Widget build(BuildContext context) {
    final rect = this.rect;
    final size = MediaQuery.sizeOf(context);
    // The portrait art and bubble stack needs roughly 600px of height. Below
    // that, use the landscape rail so the bubble's actions stay on screen.
    final short = size.height < 600;

    if (rect == null) return _fallback(context);

    final topPadding = MediaQuery.paddingOf(context).top;
    final spaceBelow = size.height - rect.bottom - 24;
    final spaceAbove = rect.top - topPadding - 24;
    final placeAbove = spaceBelow < 220 && spaceAbove > spaceBelow;

    final contentPadding = placeAbove
        ? EdgeInsets.fromLTRB(
            20,
            topPadding + 8,
            20,
            math.max(8.0, size.height - rect.top + 16),
          )
        : EdgeInsets.fromLTRB(
            20,
            math.min(size.height - 40, rect.bottom + 16),
            20,
            8,
          );

    return Stack(
      children: [
        // The scrim itself, with a rounded hole at the control. The route
        // below is non-opaque, so the live control shows through untouched.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Swallow taps on the lit control: the guide, not the app, owns
            // the screen until it closes.
            onTap: () {},
            child: CustomPaint(
              key: GuidePage.spotlightScrimKey,
              painter: _CutoutScrimPainter(
                hole: rect,
                radius: holeRadius,
                color: AppColors.charcoal.withValues(
                  alpha: GuidePage.scrimOpacity,
                ),
              ),
            ),
          ),
        ),
        // Soft gold glow hugging the hole.
        Positioned.fromRect(
          rect: rect.inflate(6),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outlineRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.24),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Dashed gold outline just outside the control, same language as the
        // lit top bar and nav.
        Positioned.fromRect(
          rect: rect.inflate(6),
          child: IgnorePointer(
            child: CustomPaint(
              key: outlineKey,
              painter: _DashedRoundedBorderPainter(
                color: AppColors.gold,
                radius: outlineRadius,
                strokeWidth: 2,
                dash: 6,
                gap: 4,
              ),
            ),
          ),
        ),
        // Second ring for a named control inside the lit area (the gold
        // Huling Araw pill). Hidden until the Gallery reports its rect.
        if (extraHighlight != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<Rect?>(
                valueListenable: extraHighlight!,
                builder: (context, extra, _) {
                  if (extra == null) return const SizedBox.shrink();
                  final ring = extra.inflate(3);
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: ring,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.30),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: ring,
                        child: CustomPaint(
                          key: extraHighlightKey,
                          painter: const _DashedRoundedBorderPainter(
                            color: AppColors.gold,
                            radius: 14,
                            strokeWidth: 2.2,
                            dash: 5,
                            gap: 3,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: contentPadding,
            child: short
                ? _LandscapeLayout(
                    art: art,
                    dialogueBuilder: dialogueBuilder,
                    skipLabel: skipLabel,
                    onSkip: onSkip,
                    stepLabel: stepLabel,
                    stepCount: stepCount,
                    activeStep: activeStep,
                  )
                : Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact =
                                MediaQuery.sizeOf(context).width < 720;
                            final baseArtHeight = compact
                                ? _Dialogue.compactArtHeight
                                : _Dialogue.wideArtHeight;
                            // Reserve the arrow row. Capping the bubble lets
                            // its copy scroll while Next/Got it stays above
                            // the fold on short phones.
                            final dialogueMax = math.max(
                              0.0,
                              constraints.maxHeight - 38,
                            );
                            // Keep Nanay visible when the lit control leaves
                            // only a narrow strip for the dialogue. Scaling
                            // the pose down is much friendlier than dropping
                            // it entirely, which used to leave the first
                            // Pakikiramay stops with text only.
                            final fittedArtHeight = math.min(
                              baseArtHeight,
                              dialogueMax,
                            );
                            // Too tight for even the title and the 56px
                            // action? Let the whole dialogue scroll instead
                            // of forcing the card to overflow.
                            final fitsBubble =
                                dialogueMax >= _minDialogueHeight;
                            final showArt =
                                fitsBubble &&
                                fittedArtHeight >= _Dialogue.minArtHeight;
                            final bubbleMaxHeight =
                                dialogueMax >= _Dialogue.minBubbleHeight
                                ? dialogueMax
                                : null;
                            final arrowLeft = (rect.center.dx - 20 - 14)
                                .clamp(
                                  0.0,
                                  math.max(0.0, constraints.maxWidth - 28),
                                )
                                .toDouble();
                            final arrow = Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: arrowLeft,
                                  top: placeAbove ? 4 : 0,
                                  bottom: placeAbove ? 0 : 4,
                                ),
                                child: _TourBouncingArrow(
                                  pointingUp: !placeAbove,
                                ),
                              ),
                            );
                            final dialogue = dialogueBuilder(
                              maxHeight: bubbleMaxHeight,
                              artHeight: showArt ? fittedArtHeight : null,
                              showArt: showArt,
                            );

                            return Align(
                              alignment: placeAbove
                                  ? Alignment.bottomCenter
                                  : Alignment.topCenter,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: placeAbove
                                      ? [
                                          dialogue,
                                          const SizedBox(height: 4),
                                          arrow,
                                        ]
                                      : [
                                          arrow,
                                          const SizedBox(height: 4),
                                          dialogue,
                                        ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Used only when the caller could not supply a rect: dim the whole app and
  /// still explain the control, so the visitor is never left without guidance.
  Widget _fallback(BuildContext context) {
    return ColoredBox(
      key: GuidePage.scrimKey,
      color: AppColors.charcoal.withValues(alpha: GuidePage.scrimOpacity),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: dialogueBuilder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills the screen with the scrim except for a rounded hole where a real
/// Gallery control sits. The route underneath is non-opaque, so the control
/// shows through at full brightness.
class _CutoutScrimPainter extends CustomPainter {
  final Rect hole;
  final Color color;
  final double radius;

  const _CutoutScrimPainter({
    required this.hole,
    required this.color,
    this.radius = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Even-odd fill instead of Path.combine(difference): on Flutter web
    // (CanvasKit/Skwasm) the difference op fails when the cutout is fully
    // contained by the screen rect, turning the scrim into a full-screen
    // cover (flutter/flutter#124675). Even-odd works on every renderer.
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    canvas.drawPath(
      scrim,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _CutoutScrimPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}

/// Paints a rounded, dashed outline used to ring the control a guide step is
/// pointing at. The same gold dashed language is used around the "Huling Araw"
/// pill and the lit navigation.
class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const _DashedRoundedBorderPainter({
    required this.color,
    this.radius = 30,
    this.strokeWidth = 2,
    this.dash = 7,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap;
  }
}

/// The real brand bar, fully lit. It is a diagram: the language pill is live
/// so visitors can try switching, while `?` and the gear are inert until the
/// guide closes.
class _LitTopBar extends StatelessWidget {
  final String? greeting;
  final String helpTooltip;

  const _LitTopBar({required this.greeting, required this.helpTooltip});

  @override
  Widget build(BuildContext context) {
    // Excluded from screen readers as a group: the bubble explains the two
    // controls, and this avoids announcing the inert help/settings buttons.
    return ExcludeSemantics(
      child: ColoredBox(
        color: AppColors.charcoal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AppBrandBar(
                  greeting: greeting,
                  helpTooltip: helpTooltip,
                  onHelpTap: () {},
                  onSettingsTap: () {},
                ),
              ),
              // Same soft gold glow + dashed ring used by the Gallery
              // spotlight, sitting just outside the lit bar.
              Positioned(
                left: -4,
                right: -4,
                top: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.26),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: -4,
                right: -4,
                top: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DashedRoundedBorderPainter(
                      color: AppColors.gold,
                      radius: 20,
                      strokeWidth: 2,
                      dash: 6,
                      gap: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouncing pointer arrow that draws attention to the currently highlighted
/// target. Loops a 6px vertical offset smoothly up and down.
class _TourBouncingArrow extends StatefulWidget {
  final bool pointingUp;

  const _TourBouncingArrow({this.pointingUp = true});

  @override
  State<_TourBouncingArrow> createState() => _TourBouncingArrowState();
}

class _TourBouncingArrowState extends State<_TourBouncingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF7EDE4);

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        final offset = widget.pointingUp
            ? _bounceAnim.value
            : -_bounceAnim.value;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: Icon(
        widget.pointingUp
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        size: 28,
        color: cream,
        shadows: [
          Shadow(color: AppColors.gold.withValues(alpha: 0.65), blurRadius: 10),
          Shadow(
            color: AppColors.goldLight.withValues(alpha: 0.45),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

// -- Nanay + speech bubble ------------------------------------------------
/// Builds the bubble for a step, optionally capped to the height available in
/// a short viewport. The landscape rail supplies the artwork separately.
typedef _DialogueBuilder =
    Widget Function({
      double? maxHeight,
      double? artHeight,
      bool showArt,
      bool showTopConnector,
    });

class _Dialogue extends StatelessWidget {
  /// The portrait figure's height on phones. Shared with [_CutoutStep] so the
  /// guide only shows art when there is actually room for it.
  static const double compactArtHeight = 240;

  /// The portrait figure's height on wider screens.
  static const double wideArtHeight = 390;

  /// The smallest scaled pose that still reads as Nanay. Below this the
  /// dialogue keeps its text-only fallback instead of showing a tiny figure.
  static const double minArtHeight = 150;

  /// Smallest capped bubble that can hold the badge, title, action, and one
  /// line of copy without overflowing. Below this the outer guide scroll view
  /// handles the full-height bubble instead.
  static const double minBubbleHeight = 190;

  final GuideArt art;
  final String title;
  final String body;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String? skipLabel;
  final VoidCallback? onSkip;
  final bool compact;
  final double? maxHeight;
  final double? artHeight;
  final bool showArt;
  final bool showTopConnector;
  final int stepCount;
  final int activeStep;
  final String stepLabel;

  const _Dialogue({
    required this.art,
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
    this.skipLabel,
    this.onSkip,
    required this.compact,
    this.maxHeight,
    this.artHeight,
    this.showArt = true,
    this.showTopConnector = false,
    required this.stepCount,
    required this.activeStep,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    // A much more prominent vector figure so Nanay is expressive, vivid, and
    // clearly visible. On phones the figure is kept smaller so the speech
    // bubble gets enough width for its actions and copy.
    final artworkHeight =
        artHeight ?? (compact ? compactArtHeight : wideArtHeight);

    final bubble = _AnimatedSpeechBubble(
      activeStep: activeStep,
      child: _SpeechBubble(
        title: title,
        body: body,
        nextLabel: nextLabel,
        onNext: onNext,
        onBack: onBack,
        skipLabel: skipLabel,
        onSkip: onSkip,
        compact: compact,
        maxHeight: maxHeight,
        stepCount: stepCount,
        activeStep: activeStep,
        stepLabel: stepLabel,
      ),
    );

    if (!showArt) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: bubble,
        ),
      );
    }

    final artWidth = artworkHeight * (compact ? 0.42 : 0.44);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Row(
          crossAxisAlignment: showTopConnector
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.only(top: showTopConnector ? 32 : 0),
                child: _AliveVector(
                  art: art,
                  width: artWidth,
                  height: artworkHeight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: showTopConnector
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, bottom: 4),
                          child: _TourBouncingArrow(pointingUp: true),
                        ),
                        bubble,
                      ],
                    )
                  : Align(alignment: Alignment.bottomLeft, child: bubble),
            ),
          ],
        ),
      ),
    );
  }
}

/// An animated wrapper for the vector illustration: the artwork itself paints
/// as soon as its frame is available (no artificial entrance delay, which used
/// to make a cached pose appear noticeably after the speech bubble), and pose
/// changes cross-fade through the [AnimatedSwitcher].
class _AliveVector extends StatelessWidget {
  final GuideArt art;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _AliveVector({
    required this.art,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      art.asset,
      fit: fit,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: guideArtFrameBuilder,
      excludeFromSemantics: true,
    );

    image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(art), child: image),
    );

    return SizedBox(width: width, height: height, child: image);
  }
}

/// An animated wrapper for the speech bubble dialog bar with a staggered entrance
/// (scale + rise + fade) and smooth step-to-step cross transitions.
class _AnimatedSpeechBubble extends StatefulWidget {
  final Widget child;
  final int activeStep;

  const _AnimatedSpeechBubble({required this.child, required this.activeStep});

  @override
  State<_AnimatedSpeechBubble> createState() => _AnimatedSpeechBubbleState();
}

class _AnimatedSpeechBubbleState extends State<_AnimatedSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final noAnim = animationsDisabled();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    if (noAnim) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(widget.activeStep),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(scale: _scaleAnim, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String title;
  final String body;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String? skipLabel;
  final VoidCallback? onSkip;
  final bool compact;
  final double? maxHeight;
  final int? stepCount;
  final int? activeStep;
  final String? stepLabel;

  const _SpeechBubble({
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
    this.skipLabel,
    this.onSkip,
    this.compact = false,
    this.maxHeight,
    this.stepCount,
    this.activeStep,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasStepBadge =
        stepCount != null && activeStep != null && stepLabel != null;
    final isLast =
        stepCount != null &&
        activeStep != null &&
        activeStep! >= stepCount! - 1;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 280,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDE4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasStepBadge || onBack != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasStepBadge)
                  Semantics(
                    label: stepLabel,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: const ShapeDecoration(
                          color: Color(0xFF6B4A3A),
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          '${activeStep! + 1}/$stepCount',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (onBack != null)
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE5D9C8),
                        border: Border.all(
                          color: const Color(0xFFD2C1AC),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 13,
                        color: Color(0xFF2B1B14),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.2,
                color: Color(0xFF2B1B14),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (maxHeight == null)
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: Color(0xFF6B5A52),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: Color(0xFF6B5A52),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isLast && onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B5A52),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    skipLabel ?? 'Skip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B5A52),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              // Keep a gutter even when the bubble is at its narrowest, so
              // Skip and Next can never touch.
              const SizedBox(width: 12),
              Flexible(
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4A3A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 18,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          nextLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Icon(
                        Icons.arrow_forward,
                        size: compact ? 16 : 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavGuideArrow extends StatelessWidget {
  const _NavGuideArrow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      width: double.infinity,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 2),
          child: _TourBouncingArrow(pointingUp: false),
        ),
      ),
    );
  }
}

// -- Lit nav bar ----------------------------------------------------------
class _HighlightedNav extends StatelessWidget {
  const _HighlightedNav();

  @override
  Widget build(BuildContext context) {
    // The copy sits at the real nav's exact position and size, so the dimmed
    // real bar underneath lines up and never peeks out. The dashed outline and
    // glow are drawn just outside those bounds, matching the Gallery ring.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -6,
                    top: -6,
                    right: -6,
                    bottom: -6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.32),
                            blurRadius: 30,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: AppColors.glowGold.withValues(alpha: 0.16),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Diagram only: the last button/Skip close the guide, then
                  // the visitor uses the real bar.
                  AppBottomNav(selectedIndex: 0, onTap: (_) {}),
                  const Positioned(
                    left: -6,
                    top: -6,
                    right: -6,
                    bottom: -6,
                    child: CustomPaint(
                      painter: _DashedRoundedBorderPainter(
                        color: AppColors.gold,
                        strokeWidth: 2,
                        dash: 6,
                        gap: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
