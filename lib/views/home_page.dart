import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/core/ui/responsive.dart';
import 'package:nita/core/utils/motion.dart';
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

part 'home/home_top_bar.dart';
part 'home/home_hero_header.dart';
part 'home/home_story_memories.dart';
part 'home/home_effects.dart';

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
    _controller.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
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
    // Named listener so it can be removed in dispose — an anonymous
    // closure here would leak the ScrollController subscription.
    _controllers[0].addListener(_mirrorStoryOffset);
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
    _controllers[0].removeListener(_mirrorStoryOffset);
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
