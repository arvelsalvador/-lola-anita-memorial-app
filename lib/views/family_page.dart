// Family tab — restyled to match the "Pamilya" screenshot layout:
// header -> stats card -> search bar -> filter chips -> centered root
// member -> horizontally-scrolling branch groups -> view-full-tree button
// -> footer note.
//
// IMPORTANT: this reuses your existing architecture as-is —
// FamilyController, FamilyModel/FamilyGroup/FamilyMember, LanguageProvider,
// AppColors, and your shared widgets (OrnamentalCard, GradientAvatar,
// TagChip, Dot, OrnamentDivider, DisplayController.initialsOf). I only used
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
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/navigation.dart';
import 'package:nita/controllers/display_controller.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/tag_chip.dart';
import 'package:nita/views/family_tree_canvas_page.dart';

part 'family/family_spines.dart';
part 'family/family_header.dart';
part 'family/family_search_bar.dart';
part 'family/family_filter_chips.dart';
part 'family/family_root_card.dart';
part 'family/family_apo_section.dart';
part 'family/family_group_section.dart';
part 'family/family_member_viewer.dart';
part 'family/family_portraits.dart';
part 'family/family_summary.dart';

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

/// The filter tabs above the family content. Each tab scrolls the page to
/// its section, and the selected tab follows the section currently in view.
enum _FamilyFilter { all, direct, apo }

/// The Family tab: header, search + filters, stats card, root member card,
/// and each family group as a horizontally-scrolling row of member cards.
class FamilyPage extends StatefulWidget {
  final ScrollController? controller;
  const FamilyPage({super.key, this.controller});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  // Distance (px) a section header may sit below the viewport top and still
  // count as "in view", so the highlight switches as the header arrives.
  static const double _switchThreshold = 60;

  final GlobalKey _anakKey = GlobalKey();
  final GlobalKey _apoKey = GlobalKey();

  _FamilyFilter _activeFilter = _FamilyFilter.all;

  ScrollController? _internalController;

  ScrollController get _scroll =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  /// The scroll offset at which [key]'s section top would sit flush with the
  /// viewport top, or null while the section is not mounted.
  double? _revealOffset(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box == null || !_scroll.hasClients) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final offset = _scroll.offset;
    final viewport = _scroll.position.viewportDimension;
    final maxExtent = _scroll.position.maxScrollExtent;
    final directOffset = _revealOffset(_anakKey);
    final apoOffset = _revealOffset(_apoKey);

    final _FamilyFilter next;
    if (apoOffset != null &&
        (offset >= apoOffset - _switchThreshold ||
            // A section pinned near the page bottom can never align to the
            // viewport top; count it as in view only once the user is
            // scrolled all the way down and the section is actually visible.
            (offset >= maxExtent - _switchThreshold &&
                offset + viewport >= apoOffset))) {
      next = _FamilyFilter.apo;
    } else if (directOffset != null &&
        offset >= directOffset - _switchThreshold) {
      next = _FamilyFilter.direct;
    } else {
      next = _FamilyFilter.all;
    }
    if (next != _activeFilter) {
      setState(() => _activeFilter = next);
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Very tall content: the section isn't built yet, so jump to the bottom
    // to force it to mount, then reveal it.
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = key.currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _selectFilter(_FamilyFilter filter) {
    setState(() => _activeFilter = filter);
    switch (filter) {
      case _FamilyFilter.all:
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      case _FamilyFilter.direct:
        _scrollToSection(_anakKey);
      case _FamilyFilter.apo:
        _scrollToSection(_apoKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    const data = FamilyController.data;
    final groups = data.groups;
    // The 'Direktang pamilya' tab targets the Mga Anak section and the
    // 'Mga Apo' tab the grandchildren section — both are bound by label,
    // not by position, so they land correctly no matter where the groups
    // sit in the data list.
    final apoIndex = groups.indexWhere(_isApoGroup);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          // Keep every section mounted so the tab's scroll targets always
          // exist, even before the page has been scrolled.
          cacheExtent: 2000,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          children: [
            const FamilyPageHeader(),
            const SizedBox(height: 16),
            const FamilySearchBar(),
            const SizedBox(height: 12),
            _FamilyFilterChips(
              active: _activeFilter,
              onSelected: _selectFilter,
            ),
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
                key: groups[i].labelKey == 'family_group_children'
                    ? _anakKey
                    : ((i == apoIndex ||
                              // The apo group renders through the straight
                              // descent grid whenever it has no age data (see
                              // _isStraightDescentGroup) — bind the scroll key
                              // by label too, or the scroll-follower can never
                              // mark the grandchildren section active.
                              _isStraightDescentGroup(groups[i]))
                          ? _apoKey
                          : null),
                group: groups[i],
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
