import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
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
  static const double scrimOpacity = 0.65;
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
  static const Key familyMemberOutlineKey = Key(
    'guide-family-member-outline',
  );

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  /// The tour-specific flag. The Gallery and Family tips have their own
  /// keys, so a visitor who finished the homepage tour still sees them.
  GuideRepository get _repo => switch (widget.tour) {
    GuideTour.gallery => const GuideRepository.gallery(),
    GuideTour.family => const GuideRepository.family(),
    GuideTour.home => const GuideRepository(),
  };

  List<GuideStep> get _steps => switch (widget.tour) {
    GuideTour.gallery => galleryGuideSteps,
    GuideTour.family => familyGuideSteps,
    GuideTour.home => guideSteps,
  };

  final VisitorRepository _visitorRepo = const VisitorRepository();

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
      default:
        break;
    }
  }

  /// Persist first, then pop. `markSeen` swallows its own errors, so this
  /// never leaves the visitor stuck on a dead button.
  void _close() {
    _repo.markSeen();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

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
      GuideTour.home => 'guide_done',
    };

    final first = _firstName ?? '';
    final greeting = first.isNotEmpty
        ? lang.t('header_greeting', {'name': first})
        : null;

    Widget buildDialogue({double? maxHeight, bool showArt = true}) => _Dialogue(
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
      showArt: showArt,
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
          holeRadius: isSearch ? 14 : (isPills ? 12 : 18),
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
          holeRadius: 14,
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
    } else {
      body = ColoredBox(
        key: GuidePage.scrimKey,
        color: AppColors.charcoal.withValues(alpha: GuidePage.scrimOpacity),
        child: switch (step.spotlight) {
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
          // Gallery and Family stops never appear inside the homepage tour;
          // those tours are built above, with their own cut-out scrim.
          GuideSpotlight.gallerySearchBar ||
          GuideSpotlight.galleryFilterPills ||
          GuideSpotlight.galleryFeaturedCard ||
          GuideSpotlight.familyMember => const SizedBox.shrink(),
        },
      );
    }

    return PopScope(
      // Back goes to the previous stop; on the first stop it closes the guide.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _repo.markSeen();
        } else if (_step > 0) {
          _goToStep(_step - 1);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.charcoal,
        ),
        // Transparent so the route below (Home, Settings, or Gallery) shows
        // through the scrim. The route itself is pushed with `opaque: false`.
        child: Scaffold(backgroundColor: Colors.transparent, body: body),
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
                      child: Image.asset(
                        art.asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _ProgressDots(
                  count: stepCount,
                  active: activeStep,
                  semanticsLabel: stepLabel,
                  showArrow: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: dialogueBuilder(
                  maxHeight: constraints.maxHeight,
                  showArt: false,
                ),
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
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 40),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              dialogueBuilder(),
                              const SizedBox(height: 6),
                              _ProgressDots(
                                count: stepCount,
                                active: activeStep,
                                semanticsLabel: stepLabel,
                                showArrow: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// Abuloy stop: the floating coin stays lit at its real dock — bottom-right,
/// just above the nav — while Nanay's bubble sits above it.
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
    final padding = MediaQuery.paddingOf(context);
    final short = MediaQuery.sizeOf(context).height < 500;

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
                // Leave the bottom-right corner to the lit coin.
                rightInset: _HighlightedAbuloy.ringSize + 8,
              ),
            ),
          )
        else
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
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
                const SizedBox(height: 6),
                _ProgressDots(
                  count: stepCount,
                  active: activeStep,
                  semanticsLabel: stepLabel,
                  showArrow: false,
                ),
                // Keep the controls above the nav. The coin floats to the
                // right of this band, so the bubble can use the space beside it.
                // The SafeArea already accounts for the bottom inset.
                const SizedBox(height: 104 + 8),
              ],
            ),
          ),
        // The ring is 8px larger than the 60px touch on every side; offsetting
        // it by the same amount leaves the coin exactly on its real dock.
        Positioned(
          right: 20 - 8,
          bottom: padding.bottom + 104 - 8,
          width: _HighlightedAbuloy.ringSize,
          height: _HighlightedAbuloy.ringSize,
          child: const _HighlightedAbuloy(),
        ),
      ],
    );
  }
}

/// The same coin the app floats on every tab, ringed in dashed gold and
/// lifted on a soft glow. Inert: the bubble's Next button moves the tour on.
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
          if (!short) ...[
            const SizedBox(height: 6),
            _ProgressDots(
              count: stepCount,
              active: activeStep,
              semanticsLabel: stepLabel,
              showArrow: true,
            ),
            const SizedBox(height: 8),
          ],
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

  /// Identifies the dashed outline so each stop has its own test key.
  final Key outlineKey;

  /// Corner radius of the hole (matching the real control) and of the dashed
  /// outline around it.
  final double holeRadius;
  final double outlineRadius;

  /// A second control inside the lit area worth ringing (the gold Huling Araw
  /// pill). Its rect arrives after the Gallery slides the row into place.
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
    final short = MediaQuery.sizeOf(context).height < 500;

    if (rect == null) return _fallback(context);

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
            padding: EdgeInsets.fromLTRB(20, rect.bottom + 16, 20, 8),
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
                            final artHeight = compact ? 180.0 : 240.0;
                            // Reserve the arrow row. Capping the bubble lets
                            // its copy scroll while Next/Got it stays above
                            // the fold on short phones.
                            final dialogueMax = math.max(
                              0.0,
                              constraints.maxHeight - 38,
                            );
                            // Too tight for even the title and the 56px
                            // action? Let the whole dialogue scroll instead
                            // of forcing the card to overflow.
                            final fitsBubble =
                                dialogueMax >= _minDialogueHeight;
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 24,
                                        bottom: 2,
                                      ),
                                      child: CustomPaint(
                                        size: Size(52, 30),
                                        painter: _CurvedArrowPainter(
                                          color: AppColors.gold,
                                          flip: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  dialogueBuilder(
                                    maxHeight: fitsBubble ? dialogueMax : null,
                                    showArt:
                                        fitsBubble && dialogueMax >= artHeight,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ProgressDots(
                        count: stepCount,
                        active: activeStep,
                        semanticsLabel: stepLabel,
                        showArrow: false,
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
            const SizedBox(height: 6),
            _ProgressDots(
              count: stepCount,
              active: activeStep,
              semanticsLabel: stepLabel,
              showArrow: false,
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
    final screen = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    final scrim = Path.combine(PathOperation.difference, screen, cutout);
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

/// The real brand bar, fully lit and outlined. It is a diagram: the language
/// pill is live so visitors can try switching, while `?` and the gear are
/// inert until the guide closes.
class _LitTopBar extends StatelessWidget {
  final String? greeting;
  final String helpTooltip;

  const _LitTopBar({required this.greeting, required this.helpTooltip});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    // Excluded from screen readers as a group: the bubble explains the two
    // controls, and this avoids announcing the inert help/settings buttons.
    return ExcludeSemantics(
      child: Stack(
        children: [
          AppBrandBar(
            greeting: greeting,
            helpTooltip: helpTooltip,
            onHelpTap: () {},
            onSettingsTap: () {},
          ),
          Positioned(
            left: 6,
            right: 6,
            top: topInset + 2,
            height: 48,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.28),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: topInset + 4,
            height: 44,
            child: const IgnorePointer(
              child: CustomPaint(
                painter: _DashedRoundedBorderPainter(
                  color: AppColors.gold,
                  radius: 14,
                  strokeWidth: 1.8,
                  dash: 7,
                  gap: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SkipButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.muted,
        minimumSize: const Size(60, 56),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      child: Text(label),
    );
  }
}

// -- Nanay + speech bubble ------------------------------------------------
/// Builds the bubble for a step, optionally capped to the height available in
/// a short viewport. The landscape rail supplies the artwork separately.
typedef _DialogueBuilder = Widget Function({double? maxHeight, bool showArt});

class _Dialogue extends StatelessWidget {
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
  final bool showArt;

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
    this.showArt = true,
  });

  @override
  Widget build(BuildContext context) {
    // A more prominent vector figure so Nanay is expressive and clearly visible.
    final artHeight = compact ? 230.0 : 320.0;

    final bubble = _SpeechBubble(
      title: title,
      body: body,
      nextLabel: nextLabel,
      onNext: onNext,
      onBack: onBack,
      skipLabel: skipLabel,
      onSkip: onSkip,
      compact: compact,
      maxHeight: maxHeight,
    );

    if (!showArt) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: bubble,
        ),
      );
    }

    final plainBubble = _SpeechBubble(
      title: title,
      body: body,
      nextLabel: nextLabel,
      onNext: onNext,
      onBack: onBack,
      skipLabel: skipLabel,
      onSkip: onSkip,
      compact: compact,
      maxHeight: maxHeight,
      plain: true,
    );
    final artWidth = artHeight * 0.42;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          padding: EdgeInsets.fromLTRB(compact ? 8 : 14, 10, 4, 6),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.charcoal.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: artWidth,
                  height: artHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Soft beige arch behind Nanay.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: artHeight * 0.18,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(artWidth),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        bottom: artHeight * 0.12,
                        child: Icon(
                          Icons.eco_outlined,
                          size: artWidth * 0.55,
                          color: AppColors.gold.withValues(alpha: 0.28),
                        ),
                      ),
                      Positioned(
                        left: -4,
                        bottom: 4,
                        child: Icon(
                          Icons.spa_outlined,
                          size: artWidth * 0.4,
                          color: AppColors.gold.withValues(alpha: 0.22),
                        ),
                      ),
                      // Nanay steps slightly out of the card at the top.
                      Positioned(
                        left: -4,
                        right: -4,
                        top: -34,
                        bottom: 4,
                        child: Image.asset(
                          art.asset,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: plainBubble),
            ],
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

  const _SpeechBubble({
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
    this.skipLabel,
    this.onSkip,
    required this.compact,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Landscape / short viewports: shave the vertical gaps so a two-line
    // title and the 56px action still leave a sliver for the body to scroll.
    final dense = maxHeight != null;

    final bodyText = Text(
      body,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: compact ? 12.5 : 14.0,
        height: 1.35,
        color: AppColors.warmMid,
      ),
    );

    return Container(
      constraints: maxHeight == null
          ? null
          : BoxConstraints(maxHeight: maxHeight!),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.16),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16,
          dense ? 4 : 6,
          compact ? 10 : 16,
          dense ? 4 : 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!dense && (onBack != null || !compact)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight.withValues(alpha: 0.25),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 13,
                          color: AppColors.warmMid,
                        ),
                      ),
                    )
                  else if (!compact)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 9.5,
                            color: AppColors.goldInk,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'LOLA ANITA',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.goldInk,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 2),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: compact ? 16.0 : 19.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.18,
                  color: AppColors.textDark,
                ),
              ),
            ),
            SizedBox(height: dense ? 2 : 4),
            if (maxHeight == null)
              bodyText
            else
              Expanded(child: SingleChildScrollView(child: bodyText)),
            SizedBox(height: dense ? 4 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (skipLabel != null && onSkip != null) ...[
                  Flexible(
                    child: _SkipButton(label: skipLabel!, onPressed: onSkip!),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warmDark,
                      foregroundColor: AppColors.goldLight,
                      elevation: 3,
                      shadowColor: AppColors.warmDark.withValues(alpha: 0.4),
                      side: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 18 : 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: compact ? 13.5 : 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    child: Text(
                      nextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// Cream bubble with a left-pointing tail, drawn as one union so the border
/// follows the tail cleanly instead of showing a seam.
class _SpeechBubblePainter extends CustomPainter {
  final Color fill;
  final Color border;

  const _SpeechBubblePainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    const bodyInset = 10.0;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyInset, 0, size.width - bodyInset, size.height),
      const Radius.circular(22),
    );

    final tailY = size.height * 0.4;
    final tail = Path()
      ..moveTo(bodyInset + 1, tailY - 10)
      ..lineTo(0, tailY)
      ..lineTo(bodyInset + 1, tailY + 10)
      ..close();

    final shape = Path.combine(
      PathOperation.union,
      Path()..addRRect(body),
      tail,
    );

    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.border != border;
  }
}

// -- Progress dots (+ the nav's hand-drawn arrow) -------------------------
class _ProgressDots extends StatelessWidget {
  final int count;
  final int active;
  final String semanticsLabel;
  final bool showArrow;

  const _ProgressDots({
    required this.count,
    required this.active,
    required this.semanticsLabel,
    required this.showArrow,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: 36,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmDark.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.charcoal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _ProgressDot(active: i == active),
                        ],
                      ],
                    ),
                  ),
                  if (showArrow)
                    const Positioned(
                      right: 26,
                      top: 1,
                      child: CustomPaint(
                        size: Size(66, 34),
                        painter: _CurvedArrowPainter(color: AppColors.gold),
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

class _ProgressDot extends StatelessWidget {
  final bool active;

  const _ProgressDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final width = active ? 20.0 : 8.0;
    const height = 8.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(99),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  final Color color;

  /// True to rotate the arrow 180°, so it points up at the Gallery search bar
  /// instead of down at the nav.
  final bool flip;

  const _CurvedArrowPainter({required this.color, this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (flip) {
      // Rotate around the centre so the same curve/arrowhead reads as an
      // upward gesture towards the search field.
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }

    final end = Offset(size.width - 4, size.height - 4);
    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(24, 2, size.width - 12, 10, end.dx, end.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Arrowhead opening up-left, so the point lands on the nav.
    final head = Path()
      ..moveTo(end.dx - 9, end.dy - 6)
      ..lineTo(end.dx, end.dy)
      ..lineTo(end.dx - 2, end.dy - 11);
    canvas.drawPath(
      head,
      paint
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.flip != flip;
  }
}

// -- Lit nav bar ----------------------------------------------------------
class _HighlightedNav extends StatelessWidget {
  const _HighlightedNav();

  @override
  Widget build(BuildContext context) {
    // The copy sits at the real nav's exact position and size, so the dimmed
    // real bar underneath lines up and never peeks out. The dashed outline and
    // glow are drawn just outside those bounds.
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
