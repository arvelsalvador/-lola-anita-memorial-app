// Family tab — restyled to match the "Pamilya" screenshot layout:
// header -> stats card -> search bar -> filter chips -> centered root
// member -> horizontally-scrolling branch groups -> view-full-tree button
// -> footer note.
//
// IMPORTANT: this reuses your existing architecture as-is —
// FamilyController, FamilyModel/FamilyGroup/FamilyMember, LanguageProvider,
// AppColors, and your shared widgets (OrnamentalCard, GradientAvatar,
// TagChip, Dot, OrnamentDivider, DisplayUtils.initialsOf). I only used
// AppColors tokens that were already present in your original file
// (gold, rose, warmDark, warmMid, textDark, muted, roseLight, roseDeep) —
// I have not seen app_constants.dart, so I didn't invent new ones.
//
// New lang keys this file expects (add these to your LanguageProvider's
// translation maps — they didn't exist in your original file):
//   family_filter_all            e.g. "Lahat"
//   family_filter_direct         e.g. "Direktang pamilya"
//   family_filter_apo            e.g. "Mga Apo"
//   family_view_full_tree        e.g. "Tingnan ang buong family tree"
//   family_footer_note           e.g. "Ang mga miyembro ng pamilya ay
//                                       maaaring ikonekta sa mga alaala."
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/core/utils/display_utils.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/data/guide/guide_repository.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/views/guide/guide_page.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/tag_chip.dart';
import 'package:nita/views/family/family_tree_canvas_page.dart';

part 'family_spines.dart';
part 'family_chrome.dart';
part 'family_search_bar.dart';
part 'family_cards.dart';
part 'family_sections.dart';
part 'family_member_viewer.dart';

/// Returns a translated label when available, otherwise a readable Filipino
/// fallback. This keeps the screen usable before new locale keys are added.
String _familyText(
  LanguageProvider lang,
  String key,
  String fallback, [
  Map<String, String>? values,
]) {
  final translated = lang.t(key, values);
  return translated == key ? fallback : translated;
}

// Pastel palette used for grandchildren who don't have a photo yet.
// Each entry is {background, text} — we cycle through these by index so
// consecutive "no-photo" cards don't repeat the same color, just like
// the LD / JD / BD circles in your screenshot.
const List<Color> _apoAvatarBg = [
  AppColors.tintLavender, // lavender
  AppColors.tintMint, // mint
  AppColors.tintPink, // pink
];
const List<Color> _apoAvatarText = [
  AppColors.accentPurple, // purple
  AppColors.accentGreen, // green
  AppColors.accentPink, // rose/pink
];

/// The Family tab: header, search, root member card, and each family
/// group as a horizontally-scrolling row of member cards.
///
/// Hosts the first-visit Family guide: a single stop that lights the first
/// member card and explains that tapping a member opens their details. It
/// opens once on the first visit and replays from the shared top-bar `?`.
class FamilyPage extends StatefulWidget {
  final ScrollController? controller;

  /// Reports the active tab index from the home shell, so the guide knows
  /// when the Family tab (2) is actually open. The page is mounted (inside
  /// the shell's IndexedStack) before that.
  final ValueNotifier<int>? activeTab;

  /// Bumped by the shell's top-bar `?` to replay the Family guide.
  final ValueListenable<int>? guideRequests;

  const FamilyPage({
    super.key,
    this.controller,
    this.activeTab,
    this.guideRequests,
  });

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  /// The Family tab's index in the home shell.
  static const int _familyTab = 2;

  /// Vertical room the guide bubble needs under the lit card. A card that
  /// leaves less than this below it is scrolled to the top before it is lit.
  static const double _bubbleRoom = 360;

  /// Marks the first member card, the guide's lit target.
  final GlobalKey _memberKey = GlobalKey();

  /// Published to the guide so the hole follows the card as the page scrolls.
  final ValueNotifier<Rect?> _memberRect = ValueNotifier<Rect?>(null);

  /// One-shot guard so the guide is scheduled at most once per page instance.
  bool _guideCheckStarted = false;

  /// True while the guide route is on screen.
  bool _guideOpen = false;

  /// Coalesces scroll notifications into one post-frame measure.
  bool _measureScheduled = false;

  /// Page scroll controller owned by this page when the shell did not provide
  /// one (standalone use and widget tests).
  ScrollController? _ownedController;

  ScrollController? get _pageController =>
      widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    widget.activeTab?.addListener(_onActiveTabChanged);
    widget.guideRequests?.addListener(_onGuideRequested);
    _ownedController = widget.controller == null ? ScrollController() : null;
    _pageController?.addListener(_onPageScrolled);
    // The page mounts with the shell before the Family tab is ever opened, so
    // this only matters if the tab was already active at mount.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowFamilyGuide(),
    );
  }

  @override
  void didUpdateWidget(covariant FamilyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeTab, widget.activeTab)) {
      oldWidget.activeTab?.removeListener(_onActiveTabChanged);
      widget.activeTab?.addListener(_onActiveTabChanged);
    }
    if (!identical(oldWidget.guideRequests, widget.guideRequests)) {
      oldWidget.guideRequests?.removeListener(_onGuideRequested);
      widget.guideRequests?.addListener(_onGuideRequested);
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.removeListener(_onPageScrolled);
      _ownedController?.dispose();
      _ownedController = widget.controller == null ? ScrollController() : null;
      _pageController?.addListener(_onPageScrolled);
    }
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onActiveTabChanged);
    widget.guideRequests?.removeListener(_onGuideRequested);
    _pageController?.removeListener(_onPageScrolled);
    _ownedController?.dispose();
    _memberRect.dispose();
    super.dispose();
  }

  /// Family lives inside the shell's IndexedStack, so it is mounted before the
  /// visitor ever opens the tab. The tab notifier is the real "opened Family"
  /// signal.
  void _onActiveTabChanged() {
    if (widget.activeTab?.value == _familyTab) _maybeShowFamilyGuide();
  }

  /// The top-bar `?` asked for the guide again. Unlike the first-visit path
  /// this ignores the "seen" flag — the button is an explicit request.
  void _onGuideRequested() => _maybeShowFamilyGuide(replay: true);

  void _maybeShowFamilyGuide({bool replay = false}) {
    if (_guideOpen) return;
    if (!replay && _guideCheckStarted) return;
    if (widget.activeTab?.value != _familyTab) return;
    _guideCheckStarted = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openFamilyGuide(replay: replay),
    );
    // The notifier listener can fire outside a frame (as in tests), so make
    // sure the callback above actually gets a frame to run at.
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _openFamilyGuide({bool replay = false}) async {
    if (!mounted || _guideOpen || widget.activeTab?.value != _familyTab) {
      return;
    }

    if (!replay) {
      final seen = await const GuideRepository.family().hasSeen();
      if (!mounted || seen || widget.activeTab?.value != _familyTab) return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      // Another overlay is on top (for example the homepage guide is still
      // fading out). Let the visitor re-enter the tab to try again.
      if (!replay) _guideCheckStarted = false;
      return;
    }

    // Bring the card on screen with room for the bubble under it, then
    // measure. Clearing first stops a stale hole from flashing mid-scroll.
    final target = _memberKey.currentContext;
    final onScreen = _memberRectOnScreen();
    final needsScroll =
        target != null && target.mounted &&
        (onScreen == null || !_hasBubbleRoom(onScreen));
    _memberRect.value = needsScroll ? null : onScreen;
    if (needsScroll) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || widget.activeTab?.value != _familyTab) return;
      _memberRect.value = _memberRectOnScreen();
    }

    if (!mounted) return;
    _guideOpen = true;
    Navigator.of(context)
        .push(
          fadeRoute(
            GuidePage(
              tour: GuideTour.family,
              familyMemberRect: _memberRect,
            ),
            opaque: false,
          ),
        )
        .then((_) {
          if (!mounted) return;
          _guideOpen = false;
          _memberRect.value = null;
        });
    // The scroll's last layout may land after the await above; publish again
    // over the next few frames so the hole still finds the card.
    _refreshMemberRect(attempts: 2);
  }

  /// Re-measures the lit card after the next frame, retrying a couple of
  /// times while the list settles (the guide opens mid-scroll).
  void _refreshMemberRect({int attempts = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_guideOpen) return;
      final rect = _memberRectOnScreen();
      if (rect != _memberRect.value) _memberRect.value = rect;
      if (rect == null && attempts > 0) {
        _refreshMemberRect(attempts: attempts - 1);
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Keeps the lit hole glued to the card if the list moves while the guide
  /// is open (the shell resetting the offset, a clamped scroll settling).
  void _onPageScrolled() {
    if (!_guideOpen || _measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted || !_guideOpen) return;
      final rect = _memberRectOnScreen();
      if (rect != _memberRect.value) _memberRect.value = rect;
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// The card's rect when it is laid out and fully on screen.
  Rect? _memberRectOnScreen() {
    final box = _memberKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      box.size.width,
      box.size.height,
    );
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.top < 0 || rect.bottom > screen.height) return null;
    return rect;
  }

  /// Whether the guide bubble fits under [rect] without scrolling itself.
  bool _hasBubbleRoom(Rect rect) =>
      rect.bottom + _bubbleRoom <= MediaQuery.sizeOf(context).height;

  @override
  Widget build(BuildContext context) {
    const data = FamilyController.data;
    final groups = data.groups;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          controller: _pageController,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          children: [
            const FamilyPageHeader(),
            const SizedBox(height: 16),
            const FamilySearchBar(),
            const SizedBox(height: 18),
            FamilyRootCard(member: data.rootMember),
            // Carry the descent line from the root card's bottom edge down
            // to the first section header: the bead marks the branch
            // origin, and that header's own spine (see _SpineBehind)
            // continues the line through into the section's branch
            // connector, so root → bus → cards reads as one unbroken line.
            if (groups.isNotEmpty)
              const _FamilyGroupConnector(height: 18, bead: true),
            for (var i = 0; i < groups.length; i++) ...[
              FamilyGroupSection(
                group: groups[i],
                // The guide lights the first card of the first section.
                firstMemberKey: i == 0 ? _memberKey : null,
                // Gather branches back to the center trunk when the next
                // section uses a center-line connector (not straight
                // descent), so the connector reads as continuous.
                // Skip the gather for sections followed by straight-descent
                // groups — those continue the per-column lines directly.
                showGather: i < groups.length - 1
                    ? (!_isApoGroup(groups[i + 1]) &&
                          !_isStraightDescentGroup(groups[i + 1]))
                    : false,
              ),
              if (i < groups.length - 1) ...[
                // The grandchildren section draws its own straight
                // per-column descent (the pager draws its own multi
                // columns) — its columns must line up with the cards
                // above it — so the generic single spine is skipped right
                // before it. Leaving it in would punch a 22px hole into
                // the straight lines coming off the cards above.
                if (!_isApoGroup(groups[i + 1]) &&
                    !_isStraightDescentGroup(groups[i + 1]))
                  const _FamilyGroupConnector()
                else
                  const SizedBox.shrink(),
              ] else
                const SizedBox(height: 18),
            ],
            const SizedBox(height: 12),
            const FamilyFooterNote(),
          ],
        ),
      ),
    );
  }
}
