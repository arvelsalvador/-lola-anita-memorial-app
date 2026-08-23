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
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/display_controller.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/tag_chip.dart';
import 'package:nita/views/family_tree_canvas_page.dart';

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
  Color(0xFFF1E9FB), // lavender
  Color(0xFFE6F5EA), // mint
  Color(0xFFFDE8F0), // pink
];
const List<Color> _apoAvatarText = [
  Color(0xFF8B5FBF), // purple
  Color(0xFF3F9142), // green
  Color(0xFFD1568B), // rose/pink
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
    final data = FamilyController.data;
    final groups = data.groups;
    // "Mga Anak" (children) is the first group; "Mga Apo" is the first group
    // rendered with the grandchildren layout. Kapatid (siblings) sits right
    // below Anak in the data, so scrolling to Anak reveals both.
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
            // No connector above the first section header — just normal
            // spacing; each branch connector starts below its own header.
            const SizedBox(height: 18),
            for (var i = 0; i < groups.length; i++) ...[
              FamilyGroupSection(
                key: i == 0 ? _anakKey : (i == apoIndex ? _apoKey : null),
                group: groups[i],
              ),
              if (i < groups.length - 1)
                const _FamilyGroupConnector()
              else
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

/// A short vertical line between two stacked group sections, so "Mga
/// Anak", "Mga Kapatid", "Mga Apo", etc. read as branches hanging off the
/// same root member instead of unconnected blocks.
class _FamilyGroupConnector extends StatelessWidget {
  const _FamilyGroupConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Center(
        child: Container(
          width: 1.5,
          color: AppColors.gold.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Org-chart style branch connector that sits directly below a group's
/// section header and above its first row of member cards: a trunk
/// descends from top-center, fans out into a horizontal bus spanning the
/// first-to-last card centers, and drops a short vertical line onto the
/// top-center of each card. With a single card the bus is skipped and the
/// trunk runs straight through to that card.
///
/// This is THE connector for every parent→children relationship in the
/// family tree — Mga Anak, Mga Kapatid, and Mga Apo all render it through
/// their shared layout paths, and any new group added to
/// FamilyController.data.groups inherits it automatically via
/// [FamilyGroupSection]. A section that renders member cards must place
/// this widget as the first child of its card column; nothing else may
/// draw lines between a header and its cards.
///
/// [cardGap] is the explicit gap between cards when the row uses fixed
/// separators (the apo pager); leave it at zero when cards are plain
/// equal-width Expanded cells.
class _TreeBranchConnector extends StatelessWidget {
  final int cardCount;
  final double cardGap;

  const _TreeBranchConnector({required this.cardCount, this.cardGap = 0});

  @override
  Widget build(BuildContext context) {
    if (cardCount <= 0) return const SizedBox.shrink();
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: CustomPaint(
        painter: _TreeBranchPainter(cardCount: cardCount, cardGap: cardGap),
      ),
    );
  }
}

/// Paints the trunk → bus → drops path. Card centers are derived purely
/// from geometry (equal-width cells, optional fixed gaps), so no measuring
/// of the actual cards is needed.
class _TreeBranchPainter extends CustomPainter {
  final int cardCount;
  final double cardGap;

  _TreeBranchPainter({required this.cardCount, this.cardGap = 0});

  static const _strokeWidth = 1.5;
  static const _busY = 10.0;

  /// How far drops extend above the bus centerline so every junction is
  /// a physical overlap (≥1px past the bus's edge) rather than a touch.
  static const _jointOverlap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      // drawPath defaults to fill — these are strokes.
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final cx = size.width / 2;

    // Trunk, bus, and drops are stroked as ONE continuous path so no two
    // separately-rasterized lines ever merely touch; plus each joint is
    // made to physically overlap by [_jointOverlap] so anti-aliasing can
    // never open a hairline (dark-on-dark-background) gap at a junction.
    final path = Path();

    // Single card: no branching — one straight drop onto it.
    if (cardCount == 1) {
      path.moveTo(cx, 0);
      path.lineTo(cx, size.height);
      canvas.drawPath(path, paint);
      return;
    }

    final List<double> centers;
    if (cardGap == 0) {
      final cellWidth = size.width / cardCount;
      centers = [for (var i = 0; i < cardCount; i++) (i + 0.5) * cellWidth];
    } else {
      final cellWidth = (size.width - cardGap * (cardCount - 1)) / cardCount;
      centers = [
        for (var i = 0; i < cardCount; i++)
          i * (cellWidth + cardGap) + cellWidth / 2,
      ];
    }

    // Trunk down from the parent spine, turning onto the bus as a single
    // connected stroke (the corner gets a proper miter join).
    path.moveTo(cx, 0);
    path.lineTo(cx, _busY);
    path.lineTo(centers.first, _busY);

    // Walk the bus left→right; each drop dips slightly ABOVE the bus
    // centerline before falling, so trunk/bus/drop overlap through every
    // junction instead of just meeting at an edge.
    for (var i = 0; i < centers.length; i++) {
      path.lineTo(centers[i], _busY - _jointOverlap);
      path.lineTo(centers[i], size.height);
      if (i < centers.length - 1) {
        path.moveTo(centers[i], _busY);
        path.lineTo(centers[i + 1], _busY);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) =>
      oldDelegate.cardCount != cardCount || oldDelegate.cardGap != cardGap;
}

/// "Pamilya" title, italic subtitle, small leaf divider underneath —
/// matches the screenshot's simple centered header (no flanking icons).
class FamilyPageHeader extends StatelessWidget {
  const FamilyPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LeafOrnament(flipped: true),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  lang.t('family_name'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _LeafOrnament(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          lang.t('family_subtitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontStyle: FontStyle.italic,
            fontSize: 13.5,
            color: AppColors.warmMid,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 4),
        const Icon(Icons.eco_outlined, size: 14, color: AppColors.gold),
      ],
    );
  }
}

class _LeafOrnament extends StatelessWidget {
  final bool flipped;

  const _LeafOrnament({this.flipped = false});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: flipped ? 3.141592653589793 : 0,
      child: const Icon(Icons.spa_outlined, size: 18, color: AppColors.gold),
    );
  }
}

/// Slim pill-shaped search field — kept close to your original tray,
/// just bumped to a full pill radius to match the screenshot.
class FamilySearchBar extends StatelessWidget {
  const FamilySearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return OrnamentalCard(
      height: 48,
      radius: 30,
      borderColor: AppColors.gold,
      borderAlpha: 0.16,
      borderWidth: 0.8,
      shadowOpacity: 0.02,
      shadowBlur: 8,
      shadowOffset: const Offset(0, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 19,
            color: AppColors.warmMid.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              lang.t('family_search_hint'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 13.5,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Icon(
            Icons.tune,
            size: 19,
            color: AppColors.warmMid.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

/// "Lahat / Direktang pamilya / Mga Apo" filter pills. The selected pill
/// follows the section currently in view; tapping one scrolls to its
/// section (see _FamilyPageState).
class _FamilyFilterChips extends StatelessWidget {
  final _FamilyFilter active;
  final ValueChanged<_FamilyFilter> onSelected;

  const _FamilyFilterChips({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _FilterPill(
          label: _familyText(lang, 'family_filter_all', 'Lahat'),
          icon: Icons.grid_view_rounded,
          selected: active == _FamilyFilter.all,
          onTap: () => onSelected(_FamilyFilter.all),
        ),
        _FilterPill(
          label: _familyText(lang, 'family_filter_direct', 'Direktang pamilya'),
          icon: Icons.people_outline,
          selected: active == _FamilyFilter.direct,
          onTap: () => onSelected(_FamilyFilter.direct),
        ),
        _FilterPill(
          label: _familyText(lang, 'family_filter_apo', 'Mga Apo'),
          icon: Icons.diversity_3_outlined,
          selected: active == _FamilyFilter.apo,
          onTap: () => onSelected(_FamilyFilter.apo),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.terracotta
                : AppColors.gold.withValues(alpha: 0.22),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.warmMid,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The featured "root" family member card (Anita in the screenshot):
/// a shrink-wrapped, centered memorial plaque — keepsake-framed photo on
/// top, then name, italic role, and a gold letter-spaced years/meta row.
class FamilyRootCard extends StatelessWidget {
  final FamilyMember member;

  const FamilyRootCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Shrink-wrapped and centered: the plaque hugs its content instead of
    // stretching edge-to-edge (capped so very long translated names can't
    // push it past a phone screen).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: OrnamentalCard(
          radius: 20,
          borderColor: AppColors.gold,
          borderAlpha: 0.2,
          borderWidth: 1,
          shadowOpacity: 0.06,
          shadowBlur: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MemberPortrait(
                    member: member,
                    size: 96,
                    ringAlpha: 0.45,
                    ringWidth: 1.6,
                    badgeSize: 22,
                    badgeIconSize: 11,
                    badgeBorderWidth: 2,
                    badgeOffset: const Offset(-2, -2),
                    initialsFontSize: 24,
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                lang.t(member.roleKey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.playfairDisplay(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: AppColors.rose,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 9,
                              color: AppColors.rose,
                            ),
                          ],
                        ),
                        if (member.statusLabel != null ||
                            member.tagline != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              if (member.statusLabel != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      member.statusLabel!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.warmMid,
                                      ),
                                    ),
                                  ],
                                ),
                              if (member.statusLabel != null &&
                                  member.tagline != null)
                                const Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              if (member.tagline != null)
                                Text(
                                  member.tagline!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (member.yearsLabel != null ||
                            member.photoCount != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (member.yearsLabel != null)
                                Text(
                                  member.yearsLabel!,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gold,
                                  ),
                                ),
                              if (member.yearsLabel != null &&
                                  member.photoCount != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '·',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              if (member.photoCount != null)
                                Text(
                                  '${member.photoCount} ${_familyText(lang, 'family_photos_with', 'larawan kasama')}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether a group should be rendered with the grandchildren layout
/// (circular avatars + age labels).
bool _isApoGroup(FamilyGroup group) =>
    group.members.isNotEmpty &&
    group.members.any((m) => m.ageYears != null || m.ageMonths != null);

/// "Mga Apo" section matching the redesign: section header with fire
/// emoji, member count badge, "Tingnan lahat" link, and a single framed
/// card showing the grandchildren in two rows of circular avatar cards
/// (name + age label), paged horizontally with page-dot indicators and
/// a next-arrow so all members can be browsed.
class FamilyApoSection extends StatefulWidget {
  final FamilyGroup group;
  const FamilyApoSection({super.key, required this.group});

  @override
  State<FamilyApoSection> createState() => _FamilyApoSectionState();
}

class _FamilyApoSectionState extends State<FamilyApoSection> {
  final PageController _pageController = PageController();

  // How many cards fit on one row and how many rows fit on one page.
  // The row count adapts to the available width so avatars never collapse
  // on narrow screens (see _columnsFor).
  int _cardsPerRow = 4;
  static const int _rowsPerPage = 2;
  static const double _cardGap = 10;
  static const double _rowGap = 14;

  int _activePage = 0;

  int get _cardsPerPage => _cardsPerRow * _rowsPerPage;

  int get _pageCount =>
      (widget.group.members.length / _cardsPerPage).ceil().clamp(1, 999);

  /// Column count for the available pager width: 4 across on wide
  /// screens, 3 on phones, 2 on very narrow screens.
  int _columnsFor(double width) => width >= 380 ? 4 : (width >= 290 ? 3 : 2);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_activePage >= _pageCount - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _prevPage() {
    if (_activePage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final group = widget.group;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        // A Wrap (not a Row) so the badge/link fall to a second line
        // instead of overflowing when the screen is narrow.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Label + fire emoji
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.t(group.labelKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('🔥', style: GoogleFonts.playfairDisplay(fontSize: 14)),
                ],
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.count} ${lang.t(group.subtitleKey)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rose,
                  ),
                ),
              ),
              // "Tingnan lahat" link — now opens the pinch-zoom tree.
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FamilyTreeCanvasPage(),
                    ),
                  );
                },
                child: Text(
                  _familyText(
                    lang,
                    'family_view_all_grandchildren',
                    'Tingnan lahat',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.roseDeep,
                    decoration: TextDecoration.underline, // hints it's tappable
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Paged avatar rows ───────────────────────────────────────
        // Each apo has its own individual card (see _ApoPageGrid); the
        // horizontal padding keeps the rows in the same place as when
        // they sat inside a single framed panel. The pager adapts its
        // column count to the available width (see _columnsFor).
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnsFor(constraints.maxWidth);
            if (columns != _cardsPerRow) {
              // The page layout changed with the window size; jump back
              // to the first page so the old page position never lingers.
              _cardsPerRow = columns;
              if (_activePage != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _activePage == 0) return;
                  setState(() => _activePage = 0);
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                });
              }
            }
            final pageCount = _pageCount;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    // Tall enough for the branch connector plus two card
                    // rows; grows only to host the new drops.
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pageCount,
                      onPageChanged: (page) {
                        if (page != _activePage) {
                          setState(() => _activePage = page);
                        }
                      },
                      itemBuilder: (context, page) {
                        final pageMembers = group.members
                            .skip(page * _cardsPerPage)
                            .take(_cardsPerPage)
                            .toList();
                        return _ApoPageGrid(
                          members: pageMembers,
                          pageOffset: page * _cardsPerPage,
                          cardsPerRow: _cardsPerRow,
                          rowsPerPage: _rowsPerPage,
                          cardGap: _cardGap,
                          rowGap: _rowGap,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Page dots + prev/next arrows row ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < pageCount; i++) ...[
                            if (i > 0) const SizedBox(width: 5),
                            _PageDot(active: i == _activePage),
                          ],
                        ],
                      ),
                      const Spacer(),
                      if (_activePage > 0)
                        _PagerArrowButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: _prevPage,
                        ),
                      if (_activePage > 0 && _activePage < pageCount - 1)
                        const SizedBox(width: 8),
                      if (_activePage < pageCount - 1)
                        _PagerArrowButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: _nextPage,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The two avatar rows inside one page of the Mga Apo pager. Every apo
/// gets its own individual card, and every card gets an equal share of
/// the row; the avatar circle is sized from that share (minus the card
/// padding) so `cardsPerRow` cards always fit side by side, even on
/// narrow screens.
class _ApoPageGrid extends StatelessWidget {
  final List<FamilyMember> members;
  final int pageOffset;
  final int cardsPerRow;
  final int rowsPerPage;
  final double cardGap;
  final double rowGap;

  const _ApoPageGrid({
    required this.members,
    required this.pageOffset,
    required this.cardsPerRow,
    required this.rowsPerPage,
    required this.cardGap,
    required this.rowGap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - cardGap * (cardsPerRow - 1)) / cardsPerRow;
        // Room for the card's horizontal padding (5 each side) plus a
        // little breathing space between the avatar and the card edge.
        final avatarSize = (cardWidth - 24).clamp(0.0, 72.0).toDouble();
        return Column(
          children: [
            // Branch connector onto this page's top card row; drawn per
            // page so the drops always line up with whichever cards are
            // paged into view.
            _TreeBranchConnector(
              cardCount: cardsPerRow < members.length
                  ? cardsPerRow
                  : members.length,
              cardGap: cardGap,
            ),
            for (var r = 0; r < rowsPerPage; r++) ...[
              if (r > 0) SizedBox(height: rowGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < cardsPerRow; c++) ...[
                    if (c > 0) SizedBox(width: cardGap),
                    if (r * cardsPerRow + c < members.length)
                      Expanded(
                        child: OrnamentalCard(
                          radius: 14,
                          borderColor: AppColors.muted,
                          borderAlpha: 0.16,
                          borderWidth: 0.8,
                          shadowOpacity: 0.03,
                          shadowBlur: 10,
                          shadowOffset: const Offset(0, 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 8,
                          ),
                          child: _ApoCard(
                            member: members[r * cardsPerRow + c],
                            colorIndex: pageOffset + r * cardsPerRow + c,
                            avatarSize: avatarSize,
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A single small dot in the page indicator. The active dot is a bit
/// wider and colored; inactive dots are plain gray circles.
class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: active
            ? AppColors.roseDeep
            : AppColors.muted.withValues(alpha: 0.35),
      ),
    );
  }
}

/// The round previous/next page arrow button under the paged rows.
class _PagerArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PagerArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.roseDeep),
      ),
    );
  }
}

/// A single circular-avatar card inside the Mga Apo rows: photo (or a
/// pastel initials circle when there's no photo yet), name, and age
/// label. The card stretches to fill its column; the avatar circle is
/// sized from the available width so cards fit on any screen.
class _ApoCard extends StatelessWidget {
  final FamilyMember member;
  final int colorIndex;
  final double avatarSize;

  const _ApoCard({
    required this.member,
    required this.colorIndex,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final initials = DisplayController.initialsOf(member.name);

    // Pick a pastel color pair based on this card's position, so a run
    // of no-photo cards doesn't all look the same (matches LD/JD/BD in
    // the reference screenshot).
    final bg = _apoAvatarBg[colorIndex % _apoAvatarBg.length];
    final fg = _apoAvatarText[colorIndex % _apoAvatarText.length];
    final initialsFontSize = (avatarSize * 0.22).clamp(10.0, 16.0);

    // Whole card is the tap target — opens the shared detail sheet for
    // this grandchild (same popup as every other relative card).
    return GestureDetector(
      onTap: () => showMemberDetailSheet(context, member),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circular portrait or pastel initials ─────────────────
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: member.photoPath == null ? bg : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: member.photoPath == null
                ? Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: initialsFontSize,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  )
                : ClipOval(
                    child: Image.asset(
                      member.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: initialsFontSize,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // ── Name ─────────────────────────────────────────────────
          Text(
            member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          // ── Age label ────────────────────────────────────────────
          if (member.ageYears != null)
            Text(
              lang.t('family_age_years', {'count': '${member.ageYears}'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                color: AppColors.muted,
              ),
            )
          else if (member.ageMonths != null)
            Text(
              lang.t('family_age_months', {'count': '${member.ageMonths}'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// One family group section, e.g. "Mga Anak · 3 anak". If the group is
/// flagged `showAsSummary`, it renders as a single wide "view all" row
/// (your existing FamilySummaryCard). If the group has members with
/// `ageYears`/`ageMonths` (grandchildren), it renders the horizontal-scrolling
/// `FamilyApoSection` instead. Otherwise it renders each member as
/// a responsive grid of thumbnail cards.
class FamilyGroupSection extends StatelessWidget {
  final FamilyGroup group;

  const FamilyGroupSection({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Grandchildren → avatar rows
    if (_isApoGroup(group)) {
      return FamilyApoSection(group: group);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        lang.t(group.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.spa_outlined,
                      size: 13,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
              Text(
                '${group.count} ${lang.t(group.subtitleKey)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (group.showAsSummary)
          FamilySummaryCard(
            viewAllLabelKey: group.viewAllLabelKey ?? group.labelKey,
            count: group.count,
          )
        else
          // Responsive member grid: pick the column count from the
          // available width (3 across on phones, 2 on narrow screens, 1 on
          // the smallest). The grid is capped at the cards' max width and
          // centered, and every row is laid out under IntrinsicHeight with
          // a stretch cross axis so all cards in the row share the same
          // height (the tallest one's) — no more ragged bottoms when one
          // member has extra tags or a longer name.
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final cols = available >= 342 ? 3 : (available >= 224 ? 2 : 1);
              final rows = <List<FamilyMember>>[];
              for (var i = 0; i < group.members.length; i += cols) {
                final end = i + cols > group.members.length
                    ? group.members.length
                    : i + cols;
                rows.add(group.members.sublist(i, end));
              }
              // Cap the grid at the per-card max width so cells never grow
              // past it on wide screens; Center keeps the block centered.
              // (A per-cell Center would hand its child loose constraints
              // and defeat the equal-height stretch.)
              final gridMaxWidth = cols * 220.0 + (cols - 1) * 12;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: gridMaxWidth),
                  child: Column(
                    children: [
                      // Branch connector onto the first card row: trunk
                      // from the spine above, bus across the row, one drop
                      // per card.
                      if (rows.isNotEmpty)
                        _TreeBranchConnector(cardCount: rows.first.length),
                      for (var r = 0; r < rows.length; r++) ...[
                        if (r > 0) const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var c = 0; c < cols; c++) ...[
                                if (c < rows[r].length)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: _MemberThumbnailCard(
                                        member: rows[r][c],
                                      ),
                                    ),
                                  )
                                else
                                  const Expanded(child: SizedBox()),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Opens the shared member-detail bottom sheet for [member]. This is THE
/// popup for every relative card — Mga Anak, Mga Kapatid, Mga Apo and any
/// future section all funnel through here; only the tapped person's data
/// differs. Dismisses via swipe-down, tapping the barrier, or the X button.
void showMemberDetailSheet(BuildContext context, FamilyMember member) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MemberDetailSheet(member: member),
  );
}

/// Reusable "full info" popup for one family member: large portrait, name,
/// relation, years/age chip, status + tagline, photo count, bio, quote,
/// and tag chips. Every block beyond name/role renders only when the model
/// has data for it, so photo-less grandchildren get a compact sheet while
/// siblings with bios get the full layout. Content scrolls when it exceeds
/// the sheet's max height (80% of the screen).
class _MemberDetailSheet extends StatelessWidget {
  final FamilyMember member;

  const _MemberDetailSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Birth–death years when present (root-style members), otherwise the
    // localized age string for grandchildren.
    String? ageText;
    if (member.yearsLabel != null) {
      ageText = member.yearsLabel;
    } else if (member.ageYears != null) {
      ageText = lang.t('family_age_years', {'count': '${member.ageYears}'});
    } else if (member.ageMonths != null) {
      ageText = lang.t('family_age_months', {'count': '${member.ageMonths}'});
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle + close button share the top band ────────
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: IconButton(
                      tooltip: lang.t('family_sheet_close'),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.warmMid,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Large portrait ──────────────────────────────────────
            Center(
              child: _MemberPortrait(
                member: member,
                size: 120,
                ringWidth: 1.6,
                initialsFontSize: 30,
              ),
            ),
            const SizedBox(height: 14),

            // ── Name + relation ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                member.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              lang.t(member.roleKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.warmMid,
              ),
            ),

            // ── Years / age chip ────────────────────────────────────
            if (ageText != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    ageText,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmDeep,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],

            // ── Status dot + tagline (root-style members) ───────────
            if (member.statusLabel != null ||
                (member.tagline)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (member.statusLabel != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      member.statusLabel!,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmDeep,
                      ),
                    ),
                  ],
                ],
              ),
              if ((member.tagline)?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    member.tagline!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      color: AppColors.warmMid,
                    ),
                  ),
                ),
              ],
            ],

            // ── Shared-photos count ─────────────────────────────────
            if (member.photoCount != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${member.photoCount} ${lang.t('family_photos_with')}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                ],
              ),
            ],

            // ── Bio ─────────────────────────────────────────────────
            if (member.bioKey != null) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('family_sheet_about').toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.t(member.bioKey!),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12.5,
                        height: 1.55,
                        color: AppColors.warmDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Quote ───────────────────────────────────────────────
            if ((member.quoteKey)?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '"${lang.t(member.quoteKey!)}"',
                  style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.warmDeep,
                  ),
                ),
              ),
            ],

            // ── Tag chips ───────────────────────────────────────────
            if (member.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in member.tags) TagChip(label: tag)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version of the root-member plaque for one member inside a
/// group: framed circular portrait (or initials placeholder), centered
/// name, italic role, and any tags — same design language as
/// FamilyRootCard.
class _MemberThumbnailCard extends StatelessWidget {
  final FamilyMember member;

  const _MemberThumbnailCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Whole card is the tap target (photo, name, or role) — opens the
    // shared detail sheet for this person. GestureDetector keeps the
    // card's visual design untouched.
    return GestureDetector(
      onTap: () => showMemberDetailSheet(context, member),
      child: OrnamentalCard(
        width: double.infinity,
        radius: 18,
        borderColor: AppColors.muted,
        borderAlpha: 0.16,
        borderWidth: 0.8,
        shadowOpacity: 0.03,
        shadowBlur: 10,
        shadowOffset: const Offset(0, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MemberPortrait(member: member),
            const SizedBox(height: 9),
            Text(
              member.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lang.t(member.roleKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontSize: 10.5,
                color: AppColors.warmMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The framed circular portrait used across the family page: gold ring,
/// white gap, clipped photo — or the initials placeholder when the member
/// has no photo yet. Sizing/ring/badge are parameterized so the root card
/// can reuse this with bolder styling instead of duplicating it.
class _MemberPortrait extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final double ringAlpha;
  final double ringWidth;
  final double badgeSize;
  final double badgeIconSize;
  final double badgeBorderWidth;
  final Offset badgeOffset;
  final double initialsFontSize;

  const _MemberPortrait({
    required this.member,
    this.size = 88,
    this.ringAlpha = 0.4,
    this.ringWidth = 1.3,
    this.badgeSize = 18,
    this.badgeIconSize = 9,
    this.badgeBorderWidth = 1.5,
    this.badgeOffset = const Offset(-1, -1),
    this.initialsFontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final initials = DisplayController.initialsOf(member.name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: ringAlpha),
                width: ringWidth,
              ),
            ),
            child: ClipOval(
              child: member.photoPath == null
                  ? _InitialsTile(
                      initials: initials,
                      fontSize: initialsFontSize,
                    )
                  : Image.asset(
                      member.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _InitialsTile(
                            initials: initials,
                            fontSize: initialsFontSize,
                          ),
                    ),
            ),
          ),
          Positioned(
            right: badgeOffset.dx,
            bottom: badgeOffset.dy,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.roseDeep,
                border: Border.all(
                  color: Colors.white,
                  width: badgeBorderWidth,
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: badgeIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsTile extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _InitialsTile({required this.initials, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF4EC),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.roseDeep,
        ),
      ),
    );
  }
}

/// A "view all" row for a group that isn't expanded into individual member
/// cards (e.g. "Mga Apo", "Mga Pamangkin"): thumbnail, localized label,
/// member count, and a chevron.
class FamilySummaryCard extends StatelessWidget {
  final String viewAllLabelKey;
  final int count;
  final VoidCallback? onTap;

  const FamilySummaryCard({
    super.key,
    required this.viewAllLabelKey,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: OrnamentalCard(
        radius: 14,
        borderColor: AppColors.muted,
        borderAlpha: 0.16,
        borderWidth: 0.7,
        shadowOpacity: 0.04,
        shadowBlur: 8,
        shadowOffset: const Offset(0, 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const GradientAvatar(
              size: 40,
              icon: Icons.people_alt_rounded,
              iconSize: 20,
              iconColor: AppColors.roseDeep,
              gradientEndAlpha: 0.6,
              borderAlpha: 0.2,
              borderWidth: 0.6,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t(viewAllLabelKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roseDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${_familyText(lang, 'family_members_word', 'miyembro')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.rose.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small footer note card at the bottom of the page, matching the
/// screenshot's "connect family to memories" strip.
class FamilyFooterNote extends StatelessWidget {
  const FamilyFooterNote({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return OrnamentalCard(
      radius: 14,
      borderColor: AppColors.gold,
      borderAlpha: 0.12,
      borderWidth: 0.7,
      shadowOpacity: 0.025,
      shadowBlur: 6,
      shadowOffset: const Offset(0, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 17,
            color: AppColors.roseDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _familyText(
                lang,
                'family_footer_note',
                'Ang mga miyembro ng pamilya ay maaaring ikonekta sa mga alaala.',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}
