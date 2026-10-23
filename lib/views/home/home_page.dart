import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/core/ui/responsive.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/controllers/home_controller.dart';

import 'package:nita/controllers/words_controller.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/models/home_model.dart';
import 'package:nita/views/family/family_page.dart';
import 'package:nita/views/condolences/condolences_page.dart';
import 'package:nita/views/gallery/gallery_page.dart';
import 'package:nita/views/settings/settings_page.dart';
import 'package:nita/views/words/words_page.dart';
import 'package:nita/widgets/app_bottom_nav.dart';
import 'package:nita/widgets/abuloy_touch.dart';
import 'package:nita/widgets/balanced_justify_text.dart';

import 'package:nita/widgets/app_brand_bar.dart';
import 'package:nita/widgets/curved_memorial_header.dart';
import 'package:nita/widgets/framed_memorial_portrait.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/reveal_on_appear.dart';
import 'package:nita/widgets/section_label.dart';
import 'package:nita/data/visitors/visitor_repository.dart';

import 'package:nita/views/guide/guide_page.dart';

part 'home_hero_header.dart';
part 'home_story_memories.dart';
part 'home_effects.dart';

/// Room kept below the memorial hero on the non-scrolling body: the top
/// bar plus a readable strip of the content panel. The hero may never
/// take more than the viewport minus this, so a short landscape phone
/// cannot push the panel off-screen.
const double _heroReservedExtent = 120;

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
  final GalleryController _galleryController = GalleryController();
  final WordsController _wordsController = WordsController();
  final CondolencesController _condolencesController = CondolencesController();
  final ForumController _forumController = ForumController();

  // Deep-link gate guard: on the web a link/bookmark/refresh containing
  // #/home lands directly on this route and never passes the splash
  // screen, where the visitor gate lives. Home therefore re-checks the
  // gate itself. Null-equivalent: the widget renders a plain warm
  // placeholder until this local (fast) check resolves.
  final VisitorRepository _visitorRepo = const VisitorRepository();
  bool _gateChecked = false;
  bool _redirectingToSplash = false;


  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTabChanged);
    _checkVisitorGate();
  }

  /// Bounces fresh devices (deep link or refresh that skipped splash) to
  /// the splash gate. Mirrors splash's philosophy: unreadable local prefs
  /// count as "not remembered", so the visitor is greeted at the door â€”
  /// the gate itself never blocks (the form always lets them in).
  Future<void> _checkVisitorGate() async {
    bool remembered = false;

    try {
      remembered = await _visitorRepo.hasVisitor();
    } catch (_) {
      remembered = false;
    }
    if (!mounted || _redirectingToSplash) return;
    if (!remembered) {
      _redirectingToSplash = true;
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != AppRoutes.splash) {
        // Replace the entire stack, not just the top route: a deep link
        // starts on '/' (splash) with '/home' pushed above it, so popping
        // first would leave two splash routes behind the gate. One splash,
        // nothing underneath â€” the splash is always the start of the flow.
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
      }
      return;
    }
    setState(() => _gateChecked = true);
    // Guide auto-start is managed by GuideController in HomeShell.
  }

  /// Opens the illustrated guide once per device, after the gate has let the
  /// visitor in. Runs in a post-frame callback so it never pushes a route
  /// during build, and checks that Home is still the current route so a fast
  /// `?` tap (or a settings push) can't stack a second guide.

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    _galleryController.dispose();
    _wordsController.dispose();
    _condolencesController.dispose();
    _forumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same warm backdrop as the splash, so the gate bounce (or the
    // millisecond-scale check) never flashes white or half-built content.
    if (!_gateChecked) {
      return const Scaffold(backgroundColor: AppColors.warmDark);
    }
    return HomeShell(
      selectedTab: _controller.selectedTab,
      onTabChanged: _controller.selectTab,
      homeController: _controller,
      galleryController: _galleryController,
      wordsController: _wordsController,
      condolencesController: _condolencesController,
      forumController: _forumController,
    );
  }
}

class HomeShell extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final HomeController homeController;
  final GalleryController galleryController;
  final WordsController wordsController;
  final CondolencesController condolencesController;
  final ForumController? forumController;

  const HomeShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.homeController,
    required this.galleryController,
    required this.wordsController,
    required this.condolencesController,
    this.forumController,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // The Story tab's live scroll offset, mirrored here by the controller
  // listener in initState. The hero's height is derived from it inside a
  // ValueListenableBuilder, so the photo header tracks the finger 1:1 as
  // the content scrolls â€” and grows back smoothly on the way up â€” without
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
  // (The IndexedStack switch itself is still instant â€” this just masks it.)
  double _contentOpacity = 1;
  Duration _contentFadeDuration = const Duration(milliseconds: 200);

  // Tells the gallery when the user switches tabs, so its "featured"
  // glows can reset when they come back to the gallery.
  final ValueNotifier<int> _activeTab = ValueNotifier<int>(0);

  // Bumped by the top-bar `?` on the Gallery tab. The grid owns the guide's
  // measured rects, so it opens the tour itself rather than the shell.
  final ValueNotifier<int> _galleryGuideRequest = ValueNotifier<int>(0);

  // Bumped by the top-bar `?` on the Family tab. The page owns its card
  // rect, so (like the Gallery) it opens the guide itself.
  final ValueNotifier<int> _familyGuideRequest = ValueNotifier<int>(0);

  // Bumped by the top-bar `?` on the Words (Mga Salita) tab.
  final ValueNotifier<int> _wordsGuideRequest = ValueNotifier<int>(0);

  // Bumped by the top-bar `?` on the Condolences (Pakikiramay) tab.
  final ValueNotifier<int> _condolencesGuideRequest = ValueNotifier<int>(0);

  late final List<ScrollController> _controllers;
  GuideController? _guideController;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (_) => ScrollController());
    // Named listener so it can be removed in dispose â€” an anonymous
    // closure here would leak the ScrollController subscription.
    _controllers[0].addListener(_mirrorStoryOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final guideController = context.read<GuideController>();
      _guideController = guideController;
      guideController.onStartGuide = _openTourForTabId;
      // The guide finishes through one shared path. Register each tab's main
      // vertical controller so that path can return the page to the top.
      guideController
        ..registerScrollController('home', _controllers[0])
        ..registerScrollController('gallery', _controllers[1])
        ..registerScrollController('family', _controllers[2])
        ..registerScrollController('tribute', _controllers[3])
        ..registerScrollController('favorites', _controllers[4]);
      guideController.setCurrentTab('home');
      guideController.maybeAutoStart('home');
    });
  }

  // Built fresh on every build() instead of cached once in initState, so
  // that if the parent ever swaps in new controller instances, the tab
  // bodies always point at the current ones rather than the ones captured
  // on first mount. This is cheap â€” these are thin wrapper widgets, and
  // IndexedStack preserves each tab's scroll position by matching widget
  // type/position, not by list identity, so rebuilding the list is safe.
  List<Widget> _buildBodies() {
    return [
      StoryPage(
        key: ValueKey('story-visit-$_storyVisitId'),
        controller: _controllers[0],
        onOpenGallery: () => widget.onTabChanged(1),
        homeController: widget.homeController,
      ),
      GalleryPage(
        controller: _controllers[1],
        activeTab: _activeTab,
        guideRequests: _galleryGuideRequest,
        galleryController: widget.galleryController,
      ),
      FamilyPage(
        controller: _controllers[2],
        activeTab: _activeTab,
        guideRequests: _familyGuideRequest,
      ),
      WordsPage(
        controller: _controllers[3],
        activeTab: _activeTab,
        guideRequests: _wordsGuideRequest,
        wordsController: widget.wordsController,
      ),
      CondolencesPage(
        controller: _controllers[4],
        activeTab: _activeTab,
        guideRequests: _condolencesGuideRequest,
        condolencesController: widget.condolencesController,
        forumController: widget.forumController,
      ),
    ];
  }

  // The shared `?` in the top bar: replay the tour that belongs to the tab
  // the visitor is on. The Gallery, Family, and Words tours need their controls
  // measured, so those pages handle it; every other tab opens the homepage
  // tour.
  String _tabIdFor(int index) => switch (index) {
        0 => 'home',
        1 => 'gallery',
        2 => 'family',
        3 => 'tribute',
        4 => 'favorites',
        _ => 'home',
      };

  void _openTourForTabId(String tabId) {
    if (!mounted) return;
    switch (tabId) {
      case 'gallery':
        _galleryGuideRequest.value++;
      case 'family':
        _familyGuideRequest.value++;
      case 'tribute':
        _wordsGuideRequest.value++;
      case 'favorites':
        _condolencesGuideRequest.value++;
      case 'home':
      default:
        Navigator.of(context).push(
          fadeRoute(const GuidePage(tour: GuideTour.home), opaque: false),
        );
    }
  }

  void _openGuideForActiveTab() {
    final guideController = context.read<GuideController>();
    final tabId = _tabIdFor(widget.selectedTab);
    guideController.startManually(tabId);
    return;
  }

  @override
  void dispose() {
    _heroTabTimer?.cancel();
    _activeTab.dispose();
    _galleryGuideRequest.dispose();
    _familyGuideRequest.dispose();
    _wordsGuideRequest.dispose();
    _condolencesGuideRequest.dispose();
    _storyOffset.dispose();
    _controllers[0].removeListener(_mirrorStoryOffset);
    final guideController = _guideController;
    if (guideController != null) {
      guideController
        ..unregisterScrollController('home', _controllers[0])
        ..unregisterScrollController('gallery', _controllers[1])
        ..unregisterScrollController('family', _controllers[2])
        ..unregisterScrollController('tribute', _controllers[3])
        ..unregisterScrollController('favorites', _controllers[4]);
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _mirrorStoryOffset() {
    // Mirror the Story tab's scroll position into the notifier. Only the
    // hero listens to it, so the per-frame cost while scrolling stays tiny.
    if (_controllers.isNotEmpty && _controllers[0].hasClients) {
      _storyOffset.value = _controllers[0].offset;
    }
  }

  // The Story tab's scroll view is the only scrollable on the home shell, and
  // it starts *below* the memorial hero. A drag that begins on the hero would
  // therefore hit nothing and make the page feel frozen, so the handlers below
  // forward it to the Story controller. The normal listener then collapses
  // the hero exactly as if the drag had started on the content.
  ScrollController get _storyController => _controllers[0];

  void _scrollStoryBy(double delta) {
    final controller = _storyController;
    if (!controller.hasClients) return;
    final position = controller.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) controller.jumpTo(target);
  }

  void _onHeroDragStart(DragStartDetails details) {
    // A tab-switch collapse/expand animation must not fight the finger.
    _heroTabTimer?.cancel();
    if (_heroTabAnimating) setState(() => _heroTabAnimating = false);
  }

  void _onHeroDragUpdate(DragUpdateDetails details) {
    _scrollStoryBy(-details.delta.dy);
  }

  void _onHeroDragEnd(DragEndDetails details) {
    final controller = _storyController;
    if (!controller.hasClients) return;
    final velocity = -(details.primaryVelocity ?? 0);
    if (velocity == 0) return;
    final position = controller.position;
    // Use the scroll view's own physics so the fling decelerates (and clamps
    // at the ends) exactly like a fling started on the content itself.
    if (position is ScrollPositionWithSingleContext) {
      position.goBallistic(velocity);
    }
  }

  void _onHeroPointerSignal(PointerSignalEvent event) {
    // Mouse wheel / trackpad on desktop web. Touch drags go through the
    // GestureDetector callbacks above.
    if (event is PointerScrollEvent) {
      _scrollStoryBy(event.scrollDelta.dy);
    }
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      if (widget.selectedTab == 0 && oldWidget.selectedTab != 0) {
        _storyVisitId++;
      }
      _activeTab.value = widget.selectedTab;
      final tabId = _tabIdFor(widget.selectedTab);
      // Duck the opacity with zero duration (an instant drop, not a fade),
      // then switch to an animated duration for the rise once the new
      // tab's scroll position has been reset â€” two different durations so
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
        // Guide bookkeeping notifies its listeners, so it must run after the
        // build phase â€” notifying during this widget's update marks provider
        // dependents dirty mid-build.
        context.read<GuideController>()
          ..setCurrentTab(tabId)
          ..maybeAutoStart(tabId);
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
      // the hero returns to finger-tracking. A timer â€” rather than scroll
      // notifications â€” avoids jumpTo's own notifications clearing the flag
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
    // Taller hero = bigger portrait: home_hero_header sizes the portrait
    // from whatever height is left after its fixed text blocks, so the
    // 150px cap there is only reached once this passes ~455.
    // The hero shares a non-scrolling Column with the top bar and the
    // content panel, which is the only flexible child. On short viewports
    // (landscape phones, ~360px) the 460 floor would leave the panel no
    // room at all and overflow the Column, so the hero is also capped at
    // [_heroReservedExtent] below the screen. Phones tall enough for the
    // 460-580 design range are unaffected.
    final expandedHeight = math.min(
      (screenHeight * 0.50).clamp(460.0, 580.0),
      math.max(0.0, screenHeight - _heroReservedExtent),
    );
    final onStoryTab = widget.selectedTab == 0;
    final onCondolencesTab = widget.selectedTab == 4;
    final locked = context.watch<GuideController?>()?.inputLocked ?? false;

    final topBar = _TopBar(
      selectedTab: widget.selectedTab,
      onOpenFamily: () => widget.onTabChanged(2),
      onOpenTab: widget.onTabChanged,
      onOpenGuide: _openGuideForActiveTab,
      backgroundColor: onCondolencesTab
          ? AppColors.warmDark.withValues(alpha: 0.62)
          : null,
    );

    final shell = Scaffold(
      backgroundColor: AppColors.cream,
      // The assistive touch floats over the whole body â€” top bar, hero,
      // and content alike â€” so it can be parked anywhere on screen.
      body: AbuloyTouchScope(
        child: Stack(
          children: [
            Column(
              children: [
                if (!onCondolencesTab) topBar,
            // The memorial hero belongs to the home page only â€” on the other
            // tabs (gallery, family, words, condolences) the pages show their
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
                final heroContent = Listener(
                  onPointerSignal: _onHeroPointerSignal,
                  child: GestureDetector(
                    // Opaque so even the transparent margins around the
                    // portrait accept the drag. The portrait's tap-to-gallery
                    // still wins on a tap â€” the drag recognizer only claims
                    // the gesture once the finger actually moves.
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: _onHeroDragStart,
                    onVerticalDragUpdate: _onHeroDragUpdate,
                    onVerticalDragEnd: _onHeroDragEnd,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: expandedHeight,
                      child: AnimatedOpacity(
                        opacity: onStoryTab ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: TickerMode(
                          // The hero sits above the IndexedStack and is only
                          // visible on the Story tab. Hidden behind opacity 0
                          // it would still run its infinite animations (the
                          // portrait's glow pulse in home_effects.dart and the
                          // curved-header shimmer in home_hero_header.dart),
                          // so mute its tickers while another tab is active.
                          enabled: onStoryTab,
                          child: _heroChild,
                        ),
                      ),
                    ),
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
                  // NestedScrollView is gone â€” nothing here needs outer/inner
                  // sliver coordination anymore, since the hero isn't a sliver.
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: onCondolencesTab
                            ? BorderRadius.zero
                            : const BorderRadius.vertical(
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
                                for (int i = 0; i < bodies.length; i++)
                                  // IndexedStack keeps every tab mounted, so
                                  // hidden tabs' infinite animations (the
                                  // story scroll-reveals, the gallery's
                                  // animation helpers, and even the
                                  // condolence candle's flame flicker) would
                                  // keep burning frames forever. TickerMode
                                  // mutes every vsync-based ticker below it
                                  // while its tab is not the active one;
                                  // muted tickers simply stop and resume
                                  // when re-enabled.
                                  TickerMode(
                                    key: ValueKey('tab-ticker-$i'),
                                    enabled: i == widget.selectedTab,
                                    child: bodies[i],
                                  ),
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
        if (onCondolencesTab)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: topBar,
          ),
      ],
    ),
  ),
);

    return PopScope(
      canPop: !locked,
      child: Stack(
        fit: StackFit.expand,
        children: [
          shell,
          if (locked)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

// -- Top bar (shell chrome) --
/// Slim fixed top bar: leaf mark + brand + visitor greeting on the left,
/// language toggle + settings on the right, with a soft fading gold seam
/// underneath. Stays at the top while the hero section scrolls away.
///
/// The greeting ("Hello, {firstName}") confirms the app recognized the
/// visitor from the splash gate (SharedPreferences via [VisitorRepository]).
/// Falls back to brand-only when loading, empty, or prefs unreadable.
class _TopBar extends StatefulWidget {
  final int selectedTab;

  /// Jumps straight to the Family tab in the bottom nav. Handed to
  /// Settings so "Tingnan sa Pamilya" lands on the real tab.
  final VoidCallback onOpenFamily;

  /// Jumps to any tab in the bottom nav. Handed to Settings so the
  /// About-Us rows land on their real tabs.
  final ValueChanged<int> onOpenTab;

  /// Replays the tour for whichever tab is active. Resolved by the shell
  /// because the Gallery's tour is opened by the grid that measures it.
  final VoidCallback onOpenGuide;

  /// Optional translucent fill used by the Pakikiramay tab so the fixed
  /// gradient shows through. Null keeps the default charcoal bar.
  final Color? backgroundColor;

  const _TopBar({
    required this.selectedTab,
    required this.onOpenFamily,
    required this.onOpenTab,
    required this.onOpenGuide,
    this.backgroundColor,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final VisitorRepository _visitorRepo = const VisitorRepository();

  /// Null = still loading, '' = no visitor, otherwise first name.
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadVisitor();
  }

  Future<void> _loadVisitor() async {
    String first = '';

    try {
      // No timeout here: SharedPreferences is local and fast, and a
      // timeout Timer breaks widget tests (fake_async pending-timer
      // assertion). Prefs unreadable still falls back to brand-only.
      final full = await _visitorRepo.localName();
      first = VisitorRepository.firstName(full);
    } catch (_) {
      // Prefs unreadable â€” stay brand-only. Never blocks the bar.
      first = '';
    }
    if (!mounted) return;
    setState(() => _firstName = first);
  }

  void _handleHomeTap() {
    final guide = context.read<GuideController?>();
    if (guide != null && (guide.inputLocked || guide.isGuideOpen)) return;

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    if (widget.selectedTab != 0) {
      widget.onOpenTab(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final first = _firstName ?? '';
    final greeting = first.isNotEmpty
        ? lang.t('header_greeting', {'name': first})
        : null;

    final homeLabel = lang.t('nav_home');
    final homeTooltip = homeLabel == 'Home'
        ? 'Go to Home'
        : (homeLabel == 'Harong' ? 'Magduman sa Harong' : 'Pumunta sa Tahanan');

    return AppBrandBar(
      backgroundColor: widget.backgroundColor,
      greeting: greeting,
      helpTooltip: lang.t('guide_help_tooltip'),
      onHelpTap: widget.onOpenGuide,
      onHomeTap: _handleHomeTap,
      homeTooltip: homeTooltip,
      onSettingsTap: () {
        Navigator.of(context).push(
          fadeRoute(
            SettingsPage(
              onViewFamily: widget.onOpenFamily,
              onOpenTab: widget.onOpenTab,
            ),
          ),
        );
      },
    );
  }
}
