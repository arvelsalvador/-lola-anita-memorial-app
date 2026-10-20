import 'dart:math' as math;

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
}

/// First-visit "spotlight" guide: the app is dimmed, one real part stays lit,
/// and Nanay explains it in a speech bubble.
///
/// Homepage tour (three stops):
///   1. Top bar — language switch and Settings.
///   2. Abuloy touch — the floating gift button.
///   3. Bottom nav — the five tabs.
///
/// Gallery tour (two stops):
///   1. The search bar — type to narrow the photo grid.
///   2. The filter pills — categories plus the candle-gated Huling Araw row.
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

  const GuidePage({
    super.key,
    this.tour = GuideTour.home,
    this.searchBarRect,
    this.filterPillsRect,
    this.onFilterPillsShown,
  });

  /// The dimming layer over the app. Deliberately translucent: the visitor
  /// should still recognise Home underneath, not stare at a black screen.
  static const double scrimOpacity = 0.65;
  static const Key scrimKey = Key('guide-scrim');
  static const Key spotlightScrimKey = Key('guide-spotlight-scrim');
  static const Key gallerySearchOutlineKey = Key(
    'guide-gallery-search-outline',
  );
  static const Key galleryPillsOutlineKey = Key('guide-gallery-pills-outline');

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  /// The tour-specific flag. The Gallery tip has its own key so a visitor who
  /// finished the homepage tour still sees it.
  GuideRepository get _repo => widget.tour == GuideTour.gallery
      ? const GuideRepository.gallery()
      : const GuideRepository();

  List<GuideStep> get _steps =>
      widget.tour == GuideTour.gallery ? galleryGuideSteps : guideSteps;

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

  /// Moves to [next] and lets the Gallery react to the new stop. Keeping this
  /// in one place means back-navigation (and future stops) triggers the same
  /// reveal as Next.
  void _goToStep(int next) {
    setState(() => _step = next);
    if (_steps[next].spotlight == GuideSpotlight.galleryFilterPills) {
      widget.onFilterPillsShown?.call();
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
    // The Gallery tip has its own closing label ("Got it") — "Start
    // exploring" reads oddly after a couple of in-tour hints.
    final doneKey = widget.tour == GuideTour.gallery
        ? 'gallery_guide_done'
        : 'guide_done';

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
      compact: compact,
      maxHeight: maxHeight,
      showArt: showArt,
    );

    final Widget body;
    if (widget.tour == GuideTour.gallery) {
      final isSearch = step.spotlight == GuideSpotlight.gallerySearchBar;
      // Blocks the dimmed Gallery underneath from the screen reader while the
      // bubble is talking; the lit control stays visible but inert.
      body = BlockSemantics(
        child: _CutoutStep(
          rect: isSearch ? widget.searchBarRect : widget.filterPillsRect,
          outlineKey: isSearch
              ? GuidePage.gallerySearchOutlineKey
              : GuidePage.galleryPillsOutlineKey,
          holeRadius: isSearch ? 14 : 12,
          outlineRadius: isSearch ? 20 : 18,
          art: step.art,
          dialogueBuilder: buildDialogue,
          skipLabel: lang.t('guide_skip'),
          onSkip: _close,
          stepLabel: stepLabel,
          stepCount: steps.length,
          activeStep: _step,
        ),
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
          // Gallery stops never appear inside the homepage tour. The Gallery
          // tour is built above, with its own cut-out scrim.
          GuideSpotlight.gallerySearchBar ||
          GuideSpotlight.galleryFilterPills => const SizedBox.shrink(),
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
    final railWidth = (width * 0.24).clamp(104.0, 168.0);

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
                _SkipButton(label: skipLabel, onPressed: onSkip),
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
                              const SizedBox(height: 4),
                              _SkipButton(label: skipLabel, onPressed: onSkip),
                              const SizedBox(height: 2),
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
                _SkipButton(label: skipLabel, onPressed: onSkip),
                const SizedBox(height: 2),
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
                    color: AppColors.gold.withValues(alpha: 0.24),
                    blurRadius: 28,
                    spreadRadius: 3,
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
            _SkipButton(label: skipLabel, onPressed: onSkip),
            const SizedBox(height: 2),
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
  });

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
                                    maxHeight: dialogueMax,
                                    showArt: dialogueMax >= artHeight,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _SkipButton(label: skipLabel, onPressed: onSkip),
                      const SizedBox(height: 2),
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
            _SkipButton(label: skipLabel, onPressed: onSkip),
            const SizedBox(height: 2),
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
            left: 8,
            right: 8,
            top: topInset + 4,
            height: 44,
            child: const IgnorePointer(
              child: CustomPaint(
                painter: _DashedRoundedBorderPainter(
                  color: AppColors.gold,
                  radius: 14,
                  strokeWidth: 1.6,
                  dash: 6,
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
        foregroundColor: AppColors.goldLight,
        minimumSize: const Size(72, 56),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: Color(0x8C1C1713), blurRadius: 8)],
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
  final bool compact;
  final double? maxHeight;
  final bool showArt;

  const _Dialogue({
    required this.art,
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.onNext,
    required this.compact,
    this.maxHeight,
    this.showArt = true,
  });

  @override
  Widget build(BuildContext context) {
    // A shorter figure on phones leaves the bubble wide enough that the
    // 56px Next button stays visible without scrolling, even in Tagalog and
    // Bicol.
    final artHeight = compact ? 180.0 : 240.0;

    final bubble = _SpeechBubble(
      title: title,
      body: body,
      nextLabel: nextLabel,
      onNext: onNext,
      compact: compact,
      maxHeight: maxHeight,
    );

    if (!showArt) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: bubble,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: artHeight * 0.4167,
                height: artHeight,
                child: Image.asset(
                  art.asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: bubble),
          ],
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
  final bool compact;
  final double? maxHeight;

  const _SpeechBubble({
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.onNext,
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
        fontSize: compact ? 15.5 : 16.5,
        height: 1.5,
        color: AppColors.warmMid,
      ),
    );

    return Container(
      constraints: maxHeight == null
          ? null
          : BoxConstraints(maxHeight: maxHeight!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SpeechBubblePainter(
          fill: AppColors.paper,
          border: AppColors.gold.withValues(alpha: 0.4),
        ),
        child: Padding(
          // Extra left padding clears the tail that points at Nanay.
          padding: EdgeInsets.fromLTRB(
            26,
            dense ? 10 : 16,
            18,
            dense ? 10 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: compact ? 22 : 25,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(height: dense ? 4 : 8),
              if (maxHeight == null)
                bodyText
              else
                // Short viewport: the action stays fixed while long copy
                // scrolls inside whatever space is left. Expanded (not
                // Flexible) keeps the scroll view from claiming a full line
                // and pushing the button past the card.
                Expanded(child: SingleChildScrollView(child: bodyText)),
              SizedBox(height: dense ? 8 : 14),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warmDark,
                      foregroundColor: AppColors.goldLight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(nextLabel),
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        width: 0.6,
                      ),
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
    final size = active ? 10.0 : 8.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 8,
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
                            color: AppColors.gold.withValues(alpha: 0.20),
                            blurRadius: 28,
                            spreadRadius: 2,
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
