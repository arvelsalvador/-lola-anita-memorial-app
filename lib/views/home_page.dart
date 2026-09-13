import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/responsive.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/controllers/memories_controller.dart';

import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/models/home_model.dart';
import 'package:nita/views/family_page.dart';
import 'package:nita/views/condolences_page.dart';
import 'package:nita/views/gallery_page.dart';
import 'package:nita/views/settings_page.dart';
import 'package:nita/views/words_page.dart';
import 'package:nita/widgets/app_bottom_nav.dart';

import 'package:nita/widgets/language_toggle.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/quote_card.dart';
import 'package:nita/widgets/section_label.dart';
import 'package:nita/widgets/timeline_widget.dart';

/// The Home tab: the app shell (top bar, collapsing memorial hero, the five
/// page tabs, floating bottom nav) plus the Story tab content (quote,
/// timeline, about, cherished memories). All Home-tab UI lives in this one
/// view file.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Composition root: every feature controller is created here (and only
  // here) and injected into the views below, so views never own or mutate
  // application state themselves.
  final HomeController _controller = HomeController();
  final MemoriesController _memoriesController = MemoriesController();
  final GalleryController _galleryController = GalleryController();
  final TributeController _tributeController = TributeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _memoriesController.dispose();
    _galleryController.dispose();
    _tributeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      selectedTab: _controller.selectedTab,
      onTabChanged: _controller.selectTab,
      memoriesController: _memoriesController,
      galleryController: _galleryController,
      tributeController: _tributeController,
    );
  }
}

class HomeShell extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final MemoriesController memoriesController;
  final GalleryController galleryController;
  final TributeController tributeController;

  const HomeShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.memoriesController,
    required this.galleryController,
    required this.tributeController,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // The Story tab's live scroll offset, mirrored here by the controller
  // listener in initState. The hero's height is derived from it inside a
  // ValueListenableBuilder, so the photo header tracks the finger 1:1 as
  // the content scrolls — and grows back smoothly on the way up — without
  // rebuilding the rest of the shell on every scroll tick.
  final ValueNotifier<double> _storyOffset = ValueNotifier<double>(0);

  // True just after a tab switch, so the hero collapse/expand plays as a
  // short animated transition instead of snap-following the (just-reset)
  // scroll offset. Cleared by a timer once the transition has finished.
  bool _heroTabAnimating = false;

  // Releases [_heroTabAnimating] after the tab-switch transition. Tracked so
  // it can be canceled on dispose and before re-scheduling on rapid tab hops.
  Timer? _heroTabTimer;

  // Bumped every time the Story tab is re-entered, forcing StoryPage to
  // remount with a fresh entrance animation and reset scroll state.
  int _storyVisitId = 0;

  // Drives a quick fade on the tab body whenever the selected tab changes,
  // so switching tabs reads as a soft cross-fade instead of an instant swap.
  // (The IndexedStack switch itself is still instant — this just masks it.)
  double _contentOpacity = 1;
  Duration _contentFadeDuration = const Duration(milliseconds: 200);

  // Tells the gallery when the user switches tabs, so its "featured"
  // glows can reset when they come back to the gallery.
  final ValueNotifier<int> _activeTab = ValueNotifier<int>(0);
  late final List<ScrollController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (_) => ScrollController());
    // Mirror the Story tab's scroll position into the notifier. Only the
    // hero listens to it, so the per-frame cost while scrolling stays tiny.
    _controllers[0].addListener(() {
      _storyOffset.value = _controllers[0].offset;
    });
  }

  // Built fresh on every build() instead of cached once in initState, so
  // that if the parent ever swaps in new controller instances, the tab
  // bodies always point at the current ones rather than the ones captured
  // on first mount. This is cheap — these are thin wrapper widgets, and
  // IndexedStack preserves each tab's scroll position by matching widget
  // type/position, not by list identity, so rebuilding the list is safe.
  List<Widget> _buildBodies() {
    return [
      StoryPage(
        key: ValueKey('story-visit-$_storyVisitId'),
        controller: _controllers[0],
        onOpenGallery: () => widget.onTabChanged(1),
        memoriesController: widget.memoriesController,
      ),
      GalleryPage(
        controller: _controllers[1],
        activeTab: _activeTab,
        galleryController: widget.galleryController,
      ),
      FamilyPage(controller: _controllers[2]),
      WordsPage(
        controller: _controllers[3],
        tributeController: widget.tributeController,
      ),
      CondolencesPage(
        controller: _controllers[4],
        tributeController: widget.tributeController,
      ),
    ];
  }

  @override
  void dispose() {
    _heroTabTimer?.cancel();
    _activeTab.dispose();
    _storyOffset.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      if (widget.selectedTab == 0 && oldWidget.selectedTab != 0) {
        _storyVisitId++;
      }
      _activeTab.value = widget.selectedTab;
      // Duck the opacity with zero duration (an instant drop, not a fade),
      // then switch to an animated duration for the rise once the new
      // tab's scroll position has been reset — two different durations so
      // the drop can't visually cancel out the rise before it starts.
      setState(() {
        _contentFadeDuration = Duration.zero;
        _contentOpacity = 0;
        // Give the hero an animated collapse/expand for the tab switch;
        // otherwise it would snap to the about-to-be-reset scroll offset.
        _heroTabAnimating = true;
      });
      // The new tab always starts at the very top, even if it was scrolled
      // down the last time it was visited.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = _controllers[widget.selectedTab];
        if (controller.hasClients) {
          controller.jumpTo(0);
        }
        // jumpTo fires the Story controller's listener, which resets the
        // notifier; for a freshly mounted tab (no clients yet) reset the
        // mirrored offset by hand.
        if (widget.selectedTab == 0) {
          _storyOffset.value = 0;
        }
        setState(() {
          _contentFadeDuration = const Duration(milliseconds: 200);
          _contentOpacity = 1;
        });
      });
      // Release the animated transition once it has had time to finish, so
      // the hero returns to finger-tracking. A timer — rather than scroll
      // notifications — avoids jumpTo's own notifications clearing the flag
      // before the expand animation even starts. The timer is tracked and
      // canceled on dispose/re-schedule so it never fires into a dead state.
      _heroTabTimer?.cancel();
      _heroTabTimer = Timer(const Duration(milliseconds: 340), () {
        if (mounted && _heroTabAnimating) {
          setState(() => _heroTabAnimating = false);
        }
      });
    }
  }

  // Memoized hero subtree: the ValueListenableBuilder below rebuilds on
  // every scroll tick, so the photo header itself is built once and only
  // the wrapper's height changes per frame. `widget` is read at tap time,
  // so the closure stays correct across parent rebuilds.
  late final Widget _heroChild = LolaHeroHeader(
    model: HomeController.grandmother,
    onTap: () => widget.onTabChanged(1),
  );

  @override
  Widget build(BuildContext context) {
    final bodies = _buildBodies();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final expandedHeight = (screenHeight * 0.46).clamp(400.0, 540.0);
    final onStoryTab = widget.selectedTab == 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _TopBar(
            onOpenFamily: () => widget.onTabChanged(2),
            onOpenTab: widget.onTabChanged,
          ),
          // The memorial hero belongs to the home page only — on the other
          // tabs (gallery, family, tribute, condolences) the pages show their
          // own headers instead. On the Story tab its height is derived
          // straight from the scroll offset, so the photo collapses and
          // re-expands in lockstep with the finger. Tab switches play a
          // short animated transition instead (see _heroTabAnimating).
          ValueListenableBuilder<double>(
            valueListenable: _storyOffset,
            builder: (context, storyOffset, _) {
              final heroHeight = onStoryTab
                  ? (expandedHeight - storyOffset).clamp(0.0, expandedHeight)
                  : 0.0;
              final heroContent = OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: expandedHeight,
                child: AnimatedOpacity(
                  opacity: onStoryTab ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _heroChild,
                ),
              );
              return ClipRect(
                child: _heroTabAnimating
                    ? AnimatedContainer(
                        key: const ValueKey('hero-collapse'),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        height: heroHeight,
                        color: AppColors.warmDark,
                        child: heroContent,
                      )
                    : Container(
                        key: const ValueKey('hero-collapse'),
                        height: heroHeight,
                        color: AppColors.warmDark,
                        child: heroContent,
                      ),
              );
            },
          ),
          Expanded(
            child: Stack(
              children: [
                // NestedScrollView is gone — nothing here needs outer/inner
                // sliver coordination anymore, since the hero isn't a sliver.
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.contentMaxWidth(context),
                        ),
                        child: AnimatedOpacity(
                          opacity: _contentOpacity,
                          duration: _contentFadeDuration,
                          curve: Curves.easeOut,
                          child: IndexedStack(
                            index: widget.selectedTab,
                            children: [
                              for (int i = 0; i < bodies.length; i++) bodies[i],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating bottom navigation.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: AppBottomNav(
                        selectedIndex: widget.selectedTab,
                        onTap: widget.onTabChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim fixed top bar: leaf logo + "nanay anita" on the left, language
/// toggle on the right, with a thin gold divider underneath. Stays at the
/// top while the hero section scrolls away.
class _TopBar extends StatelessWidget {
  /// Jumps straight to the Family tab in the bottom nav. Handed to
  /// Settings so "Tingnan sa Pamilya" lands on the real tab.
  final VoidCallback onOpenFamily;

  /// Jumps to any tab in the bottom nav. Handed to Settings so the
  /// About-Us rows land on their real tabs.
  final ValueChanged<int> onOpenTab;

  const _TopBar({required this.onOpenFamily, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1713),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                // Tight margins pin the brand to the very left edge
                // and the toggle + gear to the very right edge.
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 22,
                            color: AppColors.goldLight,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'nanay anita',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.goldLight,
                                fontFamily: 'Georgia',
                                fontFamilyFallback: [
                                  'Times New Roman',
                                  'serif',
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LanguageToggle(),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: AppColors.goldLight,
                          ),
                          onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsPage(
                              onViewFamily: onOpenFamily,
                              onOpenTab: onOpenTab,
                            ),
                          ),
                        );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Thin gold divider between the brand bar and the hero.
            Container(height: 1, color: AppColors.gold.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

/// The memorial hero: full-bleed background photo with a warm scrim, the
/// arched "In Loving Memory" header, the framed oval portrait, her name,
/// years, tagline, and a divider ornament.
class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key, required this.model, this.onTap});

  final HomeModel model;
  final VoidCallback? onTap;

  static const _photoAsset = 'assets/images/Family DP/Nanay_dp.jpg';
  static const _backgroundAsset =
      'assets/images/Editing images/memorial_header_background_raw.jpg';
  static const _maxContentWidth = 720.0;
  static const _sidePad = 18.0;
  // Top spacing inside the hero (the brand bar above it handles the status
  // bar, so this is just a small breathing gap).
  static const _topPad = 26.0;
  // "In Loving Memory" header above the portrait, styled after the memorial
  // reference graphic: uppercase serif, generous letter-spacing, pale gold,
  // arcing along the top of the portrait's circle. The block is tall because
  // the curved text dips down at its ends.
  static const _memorialBlock = 38.0;
  static const _gapMemorial = 12.0;
  static const _gapPhoto = 16.0;
  static const _nameBlock = 50.0;
  static const _gapName = 6.0;
  static const _yearsBlock = 28.0;
  static const _gapYears = 10.0;
  static const _taglineBlock = 44.0;
  static const _gapTaglineDivider = 14.0;
  static const _dividerBlock = 8.0;
  // Memorial frame PNG (converted from the user's Frame.jpg): a square image
  // with a transparent hole. Measured from the image (1920×1920), the hole is
  // an ellipse that's slightly larger at the bottom (memorial-frame taper):
  // max semi-axes ≈ 0.361 (horizontal) and 0.380 (vertical) of the frame
  // width. The photo is clipped to that ellipse + 3% overscan so it fills the
  // hole with no background gap, and stays well inside the frame's outer edge
  // (~0.41 of the width minimum). The frame PNG is the ONLY framing — the
  // photo underneath is kept plain (no border, no glow), since an extra gold
  // ring there showed through and made the frame look doubled.
  static const _frameAsset = 'assets/images/Editing images/Frame.png';
  static const _frameScale = 1.35;
  static const _holeRxFrac = 0.361; // of frameWidth, measured
  static const _holeRyFrac = 0.380; // of frameWidth, measured (bottom)
  static const _photoOverscan = 1.03;

  // Fallback fonts kick in on platforms (Android/Web) where 'Georgia'
  // isn't registered as an asset font, so text never silently disappears.
  static const _serifFallback = ['Times New Roman', 'serif'];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      color: AppColors.warmDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 380;
          final taglineFont = narrow ? 14.0 : 16.0;
          final nameFont = narrow ? 36.0 : 42.0;

          final statusTop = _topPad;
          final fixed =
              _memorialBlock +
              _gapMemorial +
              _gapPhoto +
              _nameBlock +
              _gapName +
              _yearsBlock +
              _gapYears +
              _taglineBlock +
              _gapTaglineDivider +
              _dividerBlock;
          // The portrait now includes the frame image, which is wider than the
          // photo, so divide by _frameScale to recover the photo circle size.
          final circleSize =
              ((constraints.maxHeight - statusTop - fixed) / _frameScale).clamp(
                64.0,
                150.0,
              );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background image.
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              // Warm dark scrim over the image so the cream text and gold
              // frame stay readable; darker toward the bottom where the name
              // and tagline sit.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x4D1A100D), // ~30% at top
                      Color(0x8C2E1F17), // ~55% mid
                      Color(0xE61A100D), // ~90% bottom
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: (constraints.maxWidth - 2 * _sidePad).clamp(
                        0.0,
                        _maxContentWidth - 2 * _sidePad,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: statusTop),
                          _memorialHeader(lang.t('tribute_in_loving_memory')),
                          const SizedBox(height: _gapMemorial),
                          _portrait(circleSize),
                          const SizedBox(height: _gapPhoto),
                          _name(nameFont),
                          const SizedBox(height: _gapName),
                          Semantics(
                            label:
                                'Lived from ${model.birthYear} to ${model.passingYear}',
                            child: Text(
                              '${model.birthYear} • ${model.passingYear}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: _serifFallback,
                                fontSize: 18,
                                letterSpacing: 2,
                                color: const Color(
                                  0xFFF0E4C8,
                                ).withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapYears),
                          SizedBox(
                            height: _taglineBlock,
                            child: Text(
                              // Localized tagline — add 'hero_tagline' to each
                              // language map (english/tagalog/bicol) so this
                              // switches along with the EN/TL/BC toggle.
                              lang.t('hero_tagline'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: _serifFallback,
                                fontSize: taglineFont,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFE6D3A3),
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapTaglineDivider),
                          // Thin divider line with a centered gold diamond,
                          // flush at the bottom edge of the hero so it sits
                          // exactly on the seam between the dark header and
                          // the cream body, matching the design reference.
                          const OrnamentDivider(lineAlpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _memorialHeader(String text) {
    return _CurvedMemorialHeader(text: text);
  }

  Widget _portrait(double size) {
    final frameWidth = size * _frameScale;
    return Semantics(
      label: 'Photo of ${model.name}',
      image: true,
      child: _Pressable(
        borderRadius: BorderRadius.circular(frameWidth / 2),
        onTap: onTap,
        child: SizedBox(
          width: frameWidth,
          height: frameWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _GlowPulse(size: frameWidth * 1.3),
              _photoOval(size),
              // Memorial frame PNG with a transparent hole — the photo shows
              // through it and the frame's own gold ring wraps the photo edge.
              Positioned.fill(
                child: Image.asset(
                  _frameAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOval(double size) {
    final frameWidth = size * _frameScale;
    return SizedBox(
      width: frameWidth * 2 * _holeRxFrac * _photoOverscan,
      height: frameWidth * 2 * _holeRyFrac * _photoOverscan,
      child: ClipOval(
        child: Image.asset(
          _photoAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.warmMid,
            child: const Icon(Icons.person, size: 70, color: AppColors.cream),
          ),
        ),
      ),
    );
  }

  Widget _name(double fontSize) {
    return Semantics(
      header: true,
      child: SizedBox(
        height: _nameBlock,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            model.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: _serifFallback,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.cream,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// "In Loving Memory" header that arcs along the top of a circle, matching
/// the arched memorial reference graphic. Each letter is rotated to follow
/// the curve, and a small gold dot flanks each end of the arch.
class _CurvedMemorialHeader extends StatefulWidget {
  const _CurvedMemorialHeader({required this.text});

  final String text;

  static const _gold = Color(0xFFE6D3A3);
  // Radius of the arc the text follows. Larger = gentler curve.
  static const _radius = 300.0;
  // Arc-length gap between the text ends and the flanking dots.
  static const _dotGap = 6.0;
  static const _dotRadius = 2.5;

  @override
  State<_CurvedMemorialHeader> createState() => _CurvedMemorialHeaderState();
}

class _CurvedMemorialHeaderState extends State<_CurvedMemorialHeader>
    with SingleTickerProviderStateMixin {
  // One cycle sweeps a soft light across the letters once, then rests
  // before repeating — an occasional shimmer, not a constant glimmer.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final style = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: LolaHeroHeader._serifFallback,
      fontSize: 13,
      letterSpacing: 4,
      color: _CurvedMemorialHeader._gold,
      height: 1.1,
    );

    // Lay the whole string out once to get its line height, then lay each
    // character out individually so we can place them along the arc by their
    // own widths (letter-spacing included).
    final whole = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final chars = <TextPainter>[];
    var totalWidth = 0.0;
    for (final rune in widget.text.runes) {
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(rune), style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      chars.add(tp);
      totalWidth += tp.width;
    }

    final glyphHeight = whole.height;
    const radius = _CurvedMemorialHeader._radius;
    const dotGap = _CurvedMemorialHeader._dotGap;
    const dotRadius = _CurvedMemorialHeader._dotRadius;
    // The text spans an arc of totalWidth / radius radians; the dots sit
    // just past the text's ends on the same circle.
    final dotAngle = totalWidth / radius / 2 + dotGap / radius;
    final drop = radius * (1 - math.cos(dotAngle));
    final width = 2 * (radius * math.sin(dotAngle) + dotRadius);
    final height = drop + glyphHeight + dotRadius + 2;

    return Semantics(
      label: widget.text,
      header: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(width, height),
            painter: _CurvedTextPainter(
              chars: chars,
              totalWidth: totalWidth,
              glyphHeight: glyphHeight,
              radius: radius,
              dotAngle: dotAngle,
              dotRadius: dotRadius,
              color: _CurvedMemorialHeader._gold,
              shimmerPhase: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  _CurvedTextPainter({
    required this.chars,
    required this.totalWidth,
    required this.glyphHeight,
    required this.radius,
    required this.dotAngle,
    required this.dotRadius,
    required this.color,
    required this.shimmerPhase,
  });

  final List<TextPainter> chars;
  final double totalWidth;
  final double glyphHeight;
  final double radius;
  final double dotAngle;
  final double dotRadius;
  final Color color;

  /// 0..1, looping continuously. Only the first [_sweepWindow] of each
  /// cycle actually sweeps a light across the text; the rest of the cycle
  /// is a quiet rest before the next pass.
  final double shimmerPhase;

  static const _sweepWindow = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Arc center sits below the text so the letters ride the circle's top.
    final cy = radius + glyphHeight / 2;

    // Gold dots at the two ends of the arch.
    final dotPaint = Paint()..color = color.withValues(alpha: 0.7);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(
          cx + radius * math.sin(sign * dotAngle),
          cy - radius * math.cos(dotAngle),
        ),
        dotRadius,
        dotPaint,
      );
    }

    // Soft highlight traveling along the arc during the sweep window,
    // sitting behind the letters like a light briefly catching the gold.
    if (shimmerPhase <= _sweepWindow && totalWidth > 0) {
      final sweepT = Curves.easeInOut.transform(shimmerPhase / _sweepWindow);
      final highlightPos = -0.15 + sweepT * 1.3; // travels with slight overrun
      if (highlightPos >= -0.05 && highlightPos <= 1.05) {
        final angle = (highlightPos - 0.5) * (totalWidth / radius);
        final hx = cx + radius * math.sin(angle);
        final hy = cy - radius * math.cos(angle);
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(hx, hy), radius: 16));
        canvas.drawCircle(Offset(hx, hy), 16, glowPaint);
      }
    }

    // Letters laid along the arc, each rotated to follow the curve.
    var offset = -totalWidth / 2;
    for (final tp in chars) {
      final w = tp.width;
      final angle = (offset + w / 2) / radius;
      final x = cx + radius * math.sin(angle);
      final y = cy - radius * math.cos(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-w / 2, -tp.height / 2));
      canvas.restore();
      offset += w;
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter oldDelegate) {
    return oldDelegate.shimmerPhase != shimmerPhase ||
        oldDelegate.chars.length != chars.length ||
        oldDelegate.totalWidth != totalWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dotAngle != dotAngle;
  }
}

/// The Story tab (Home tab index 0): her words, her journey, about her,
/// and the cherished memories section.
class StoryPage extends StatelessWidget {
  final ScrollController? controller;

  /// Called when the visitor taps anything that points at the gallery
  /// ("Tingnan sa Galeri", "Buksan ang mga larawan"). The home shell uses
  /// it to switch to the gallery tab.
  final VoidCallback? onOpenGallery;

  final MemoriesController memoriesController;

  const StoryPage({
    super.key,
    this.controller,
    this.onOpenGallery,
    required this.memoriesController,
  });

  @override
  Widget build(BuildContext context) {
    final data = HomeController.data;
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      controller: controller,
      primary: false,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ScrollReveal(
                id: 'label-her-words',
                index: 0,
                child: SectionLabel(lang.t('section_her_words')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'quote-card',
                index: 1,
                child: QuoteCard(
                  quote: lang.t(data.quoteKey),
                  attribution: lang.t(data.quoteAttributionKey),
                ),
              ),
              const SizedBox(height: 28),
              _ScrollReveal(
                id: 'label-her-journey',
                index: 2,
                child: SectionLabel(lang.t('section_her_journey')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'timeline',
                index: 3,
                child: TimelineWidget(events: data.timeline),
              ),
              const SizedBox(height: 28),
              _ScrollReveal(
                id: 'label-about-her',
                index: 4,
                child: SectionLabel(lang.t('section_about_her')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'about-card',
                index: 5,
                child: AboutCard(
                  text: lang.t(data.aboutKey),
                  onTap: onOpenGallery,
                ),
              ),
              const SizedBox(height: 32),
              _ScrollReveal(
                id: 'label-cherished-memories',
                index: 6,
                child: SectionLabel(lang.t('section_cherished_memories')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'memories-section',
                index: 7,
                floatUp: true,
                child: MemoriesSection(
                  memoriesController: memoriesController,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Simple white card with the "about her" story text.
class AboutCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const AboutCard({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.rose,
        borderAlpha: 0.12,
        borderWidth: 0.5,
        shadowOpacity: 0,
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: AppTextStyles.serifBody,
        ),
      ),
    );
  }
}

/// The cherished-memories block: the memory cards. Lives on the home page
/// (the Story tab). The old filter pill row (Lahat / Buhay / Pamilya /
/// Pagdiriwang) was removed — the categories were redundant with the
/// gallery's own filters, and with them gone the "Lahat" pill had nothing
/// left to filter.
class MemoriesSection extends StatefulWidget {
  final MemoriesController memoriesController;

  const MemoriesSection({
    super.key,
    required this.memoriesController,
  });

  @override
  State<MemoriesSection> createState() => _MemoriesSectionState();
}

class _MemoriesSectionState extends State<MemoriesSection> {
  @override
  void initState() {
    super.initState();
    widget.memoriesController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.memoriesController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final memories = MemoriesController.data.memories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < memories.length; i++) ...[
          _StaggeredEntry(
            key: ValueKey(memories[i].id),
            index: i,
            child: MemoryCard(
              memory: memories[i],
              index: i,
            ),
          ),
          if (i != memories.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Botanical spray above a memory card's title — the approved design
/// (Memories_design.png) trimmed to its artwork band
/// (Memories_design_trim.png, 2002x492, no transparent padding). The
/// original canvas is 2304x1536 with the spray occupying only a quarter
/// of its height, which rendered it tiny; the trim lets BoxFit.contain
/// scale the spray to the full text-column width (tall as the width
/// allows, 35–48px on phones).
/// Vertical budget (worst case: 2-line title + 6-line body): 48px accent
/// box + 4px gap + 42px title + 6px gap + 108px body = 208px, inside the
/// 210.6px available (244px card, 16px vertical padding, 1.4px border).
class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  static const _assetPath =
      'assets/images/Editing images/Memories_design_trim.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          _assetPath,
          height: 48,
          fit: BoxFit.contain,
          // The spray is purely decorative — never let an asset problem
          // break the card's layout.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Memory card with a full-bleed photo occupying roughly a third of the
/// card, flush against one rounded edge — left on even-indexed cards,
/// right on odd-indexed ones, so the list reads as an alternating column
/// rather than a repeating row. A small gold accent, the title row, and
/// the body fill the remaining space. The whole card is tappable to open
/// the gallery.
class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final int index;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.index,
  });

  static const double _cardHeight = 244;
  static const double _photoWidth = 150;
  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final photoOnLeft = index.isEven;
    // Unique per card, needed so Hero can match this thumbnail to the
    // right full-screen preview when several cards are on screen.
    final heroTag = 'memory-photo-${memory.id}';
    final photoRadius = BorderRadius.horizontal(
      left: photoOnLeft ? const Radius.circular(_radius) : Radius.zero,
      right: photoOnLeft ? Radius.zero : const Radius.circular(_radius),
    );

    // The photo holds its usual share of the card on normal widths but
    // yields ground on narrow phones, so the text side keeps enough room
    // for the title row's bookmark icon and the copy. Sits at the full 150px from
    // ~390px screens up; the 96px floor keeps a visible photo strip on
    // very narrow viewports.
    final photoWidth = math.max(
      96.0,
      math.min(_photoWidth, (MediaQuery.sizeOf(context).width - 40) * 0.44),
    );

    // The photo is the card's only tap target — it opens a full-screen
    // preview. The rest of the card (title, body) is static text; the
    // gallery is reached from the section header instead.
    final photo = _Pressable(
      borderRadius: photoRadius,
      onTap: () => _openMemoryPhotoPreview(
        context,
        memory: memory,
        heroTag: heroTag,
      ),
      child: Hero(
        tag: heroTag,
        child: _MemoryPhoto(
          assetPath: memory.image,
          width: photoWidth,
          height: _cardHeight,
          borderRadius: photoRadius,
        ),
      ),
    );

    final content = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _TitleAccent(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang.t(memory.titleKey),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serifHeading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.bookmark_border_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // The body is summarized to fit ~6 lines on the card's text
            // column (12px caption, 1.5 line height) at typical phone
            // widths — no trailing ellipsis. The no-ellipsis probe test
            // in test/memory_card_overflow_test.dart enforces this.
            Text(
              lang.t(memory.bodyKey),
              textAlign: TextAlign.justify,
              style: AppTextStyles.caption,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.14),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: photoOnLeft ? [photo, content] : [content, photo],
      ),
    );
  }
}

/// The photo content for a memory's photo slot: the memory's own bundled
/// asset when one is wired in ([assetPath], from MemoryItem.image), the
/// soft gradient placeholder when it isn't. Shared by the card thumbnail
/// and the full-screen preview so the Hero flight lands on exactly the
/// same picture the thumbnail showed, at whatever size the destination
/// needs.
///
/// A missing asset must never take the layout down with it: the default
/// load-failure widget is an unwrapped error string that overflows this
/// fixed-size slot (the "RIGHT OVERFLOWED BY 104 PIXELS" seen when the
/// Best Pictures folder wasn't bundled), so load failures fall back to
/// the placeholder.
class _MemoryPhoto extends StatelessWidget {
  final String? assetPath;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double iconSize;

  const _MemoryPhoto({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return _PhotoPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        iconSize: iconSize,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _PhotoPlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
          iconSize: iconSize,
        ),
      ),
    );
  }
}

/// Placeholder for a memory's photo — a soft rose/gold gradient block with
/// an image icon, standing in until real photos are wired in. Used directly
/// by [_MemoryPhoto], which wraps the wired-in assets and falls back to
/// this placeholder when an asset is missing. The sizing, clipping, and
/// alternating placement in MemoryCard stay the same.
class _PhotoPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double iconSize;

  const _PhotoPlaceholder({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rose.withValues(alpha: 0.45),
              AppColors.gold.withValues(alpha: 0.45),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Opens a full-screen preview of a memory's photo. This is intentionally
/// separate from the card's own onTap (which opens the gallery tab) — the
/// photo has its own destination, not the gallery.
void _openMemoryPhotoPreview(
  BuildContext context, {
  required MemoryItem memory,
  required String heroTag,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _MemoryPhotoPreview(memory: memory, heroTag: heroTag),
        );
      },
    ),
  );
}

/// Full-screen photo viewer. Shares a Hero tag with the thumbnail in
/// MemoryCard, so the photo grows smoothly from its card position into
/// the full-screen view instead of just cross-fading in. Tap anywhere,
/// or the close button, to dismiss.
class _MemoryPhotoPreview extends StatelessWidget {
  final MemoryItem memory;
  final String heroTag;
  const _MemoryPhotoPreview({required this.memory, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).width * 0.86;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: heroTag,
                  child: _MemoryPhoto(
                    assetPath: memory.image,
                    width: side,
                    height: side,
                    borderRadius: BorderRadius.circular(20),
                    iconSize: 64,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared micro-interaction widgets, private to this file.
// ---------------------------------------------------------------------

/// Wraps a tappable card/button with a subtle press-down scale, so taps
/// feel responsive beyond the bare ink ripple. Keep durations short (≤150ms)
/// so it reads as instant feedback, not a distinct animation.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const _Pressable({
    required this.child,
    required this.borderRadius,
    this.onTap,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Reveals [child] with a fade + directional slide the first time it
/// becomes meaningfully visible while scrolling — not on mount. Content
/// below the fold starts fully hidden until the user actually scrolls it
/// into view, then it settles in once and stays.
class _ScrollReveal extends StatefulWidget {
  final String id;
  final int index;
  final Widget child;
  final bool floatUp;

  const _ScrollReveal({
    required this.id,
    required this.index,
    required this.child,
    this.floatUp = false,
  });

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: _beginOffset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  bool _revealed = false;
  Timer? _delayTimer;
  @override
  bool get wantKeepAlive => true;

  Offset get _beginOffset {
    if (widget.floatUp) return const Offset(0, 0.08);
    return Offset(widget.index.isEven ? -0.10 : 0.10, 0.04);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_revealed || info.visibleFraction <= 0.15) return;
    _revealed = true;
    _delayTimer = Timer(
      Duration(milliseconds: 150 + 80 * (widget.index % 4)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return VisibilityDetector(
      key: Key('scroll-reveal-${widget.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

/// Fades and slides a list item in on first build, offset by [index] so a
/// list of cards animates in as a gentle cascade rather than popping in all
/// at once. Cheap — no AnimationController needed.
class _StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A gentle breathing-opacity placeholder shown in place of counts that are
/// still loading (e.g. the gallery photo count), instead of a static "…"
/// that gives no sense of something being in progress.
class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

/// A slow, quiet warmth behind the portrait frame — a soft radial glow that
/// breathes in and out over several seconds. Meant to feel like a candle's
/// light, not a UI effect; kept subtle on purpose.
class _GlowPulse extends StatefulWidget {
  final double size;
  const _GlowPulse({required this.size});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFE6D3A3).withValues(alpha: 0.10 + 0.16 * t),
                const Color(0xFFE6D3A3).withValues(alpha: 0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
