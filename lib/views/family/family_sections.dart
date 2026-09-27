part of 'family_page.dart';

// -- Group section (dispatcher + grid) --
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

    final Widget header = Padding(
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
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.spa_outlined, size: 13, color: AppColors.gold),
              ],
            ),
          ),
          Text(
            '${group.count} ${lang.t(group.subtitleKey)}',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + the gap beneath it. For card-grid sections the pair is
        // wrapped in a _SpineBehind so the descent line runs unbroken from
        // above (the root card, or the previous group) through the header's
        // empty middle and lands on the branch connector below. A "view
        // all" summary row has no connector to land on, so it keeps plain
        // spacing. The grandchildren grid instead draws straight
        // per-column lines through its header (no bus) — see the
        // [straight] branch below.
        if (group.showAsSummary) ...[
          header,
          const SizedBox(height: 12),
          FamilySummaryCard(
            viewAllLabelKey: group.viewAllLabelKey ?? group.labelKey,
            count: group.count,
          ),
        ] else
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final cols = available >= 342 ? 3 : (available >= 224 ? 2 : 1);

              // Straight per-column descent for the grandchildren grid:
              // lines run from the section above, straight through the
              // header onto every branch column, and continue card→card
              // down each column — no horizontal bus. [_isApoGroup] routes
              // the group to FamilyApoSection (the pager) when the data
              // has ages; without ages it falls back to this grid and
              // keeps the same straight-line look.
              final straight = _isStraightDescentGroup(group);

              // Branch columns follow family branches: consecutive members
              // sharing a parentName stack into one vertical column — one
              // column per parent's children (Hanna Lumbao & Audrey Lumbao under Gernan,
              // Rodel Lumbao Jr. & Rose-ann Lumbao under Rodel Lumbao Sr., Arvel/Aivan/Honey/Daniel Salvador
              // under Lorie) — so every branch descends in its own column,
              // matching the "Mga Apo" design. When any member has no
              // parent on record the grouping is ambiguous, so fall back
              // to the generic equal-chunk rows.
              final branches = <List<FamilyMember>>[];
              if (straight &&
                  group.members.isNotEmpty &&
                  group.members.every((m) => m.parentName != null)) {
                for (final member in group.members) {
                  final last = branches.isEmpty ? null : branches.last;
                  if (last != null &&
                      last.first.parentName == member.parentName) {
                    last.add(member);
                  } else {
                    branches.add([member]);
                  }
                }
              }

              // Branch columns render one vertical stack per parent; every
              // other case (generic sections and ambiguous straight data)
              // keeps the equal-chunk rows.
              final useColumns = straight && branches.isNotEmpty;
              final rows = <List<FamilyMember>>[];
              if (!useColumns) {
                for (var i = 0; i < group.members.length; i += cols) {
                  final end = i + cols > group.members.length
                      ? group.members.length
                      : i + cols;
                  rows.add(group.members.sublist(i, end));
                }
              }

              // Branch columns give every parent's stack its own column, so
              // the straight grid renders exactly one column per branch
              // (three for the current data). Generic grids keep the
              // breakpoint columns.
              final plotCols = useColumns ? branches.length : cols;

              // Cap the grid at the per-card max width so cells never grow
              // past it on wide screens; Center keeps the block centered.
              // (A per-cell Center would hand its child loose constraints
              // and defeat the equal-height stretch.)
              final gridMaxWidth = plotCols * 220.0 + (plotCols - 1) * 12;

              // The header's through-lines and the first descent must line
              // up with the first card of every branch column — each
              // column always opens with a card, so the straight grid
              // carries one line per column. Generic grids line up with
              // the first row's card count.
              final headerLines = useColumns
                  ? plotCols
                  : (cols < group.members.length ? cols : group.members.length);

              // Branch columns give every card a full grid cell; shrink the
              // portrait the same way so a three-across phone column never
              // overflows its card.
              final cellWidth =
                  (available < gridMaxWidth ? available : gridMaxWidth) /
                  plotCols;
              final portraitSize = useColumns
                  ? (cellWidth - 36.0).clamp(28.0, 88.0)
                  : null;

              final Widget grid = useColumns
                  ? Column(
                      children: [
                        // Descent from the header onto the first card of
                        // every branch column — straight per-column lines
                        // continuing the ones behind the header.
                        SizedBox(
                          height: 28,
                          child: _SpineLines(
                            columns: plotCols,
                            beadBottom: true,
                          ),
                        ),
                        // One vertical stack per parent branch: cards chain
                        // card→card with short beaded lines in the gaps, and
                        // a branch simply ends when its children run out
                        // (Lorie's four stack deepest; the shorter columns
                        // leave clean ground below).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final branch in branches)
                              Expanded(
                                child: Column(
                                  children: [
                                    for (var i = 0; i < branch.length; i++) ...[
                                      if (i > 0)
                                        const SizedBox(
                                          height: 12,
                                          child: _SpineLines(
                                            columns: 1,
                                            beadTop: true,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: _MemberThumbnailCard(
                                          member: branch[i],
                                          portraitSize: portraitSize,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Descent onto the first card row: a bus fanning
                        // out from the spine above (grid sections).
                        if (rows.isNotEmpty)
                          _TreeBranchConnector(cardCount: rows.first.length),
                        for (var r = 0; r < rows.length; r++) ...[
                          if (r > 0) const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var c = 0; c < plotCols; c++) ...[
                                  if (c < rows[r].length)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: _MemberThumbnailCard(
                                          member: rows[r][c],
                                          portraitSize: portraitSize,
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
                    );

              if (!useColumns) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SpineBehind(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [header, const SizedBox(height: 12)],
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: gridMaxWidth),
                        child: grid,
                      ),
                    ),
                  ],
                );
              }

              // Straight descent: the header lives inside the capped grid
              // width so its per-column lines align with the branch column
              // card centers above and below it.
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: gridMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Continuation segment from the cards above down to
                      // the header.
                      SizedBox(
                        height: 18,
                        child: _SpineLines(
                          columns: plotCols,
                          count: headerLines,
                          beadTop: true,
                        ),
                      ),
                      _SpineBehind(
                        columns: plotCols,
                        count: headerLines,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [header, const SizedBox(height: 12)],
                        ),
                      ),
                      grid,
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

// -- Apo pager section --
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
  int _cardsPerRow = 3;
  static const int _rowsPerPage = 2;
  // No extra gap between cells — the pager uses the exact same
  // equal-width Expanded cell math as the member grid above, so the
  // per-column descent lines land precisely on the beads.
  static const double _cardGap = 0;
  static const double _rowGap = 14;

  int _activePage = 0;

  int get _cardsPerPage => _cardsPerRow * _rowsPerPage;

  int get _pageCount =>
      (widget.group.members.length / _cardsPerPage).ceil().clamp(1, 999);

  /// Column count for the available pager width — deliberately the same
  /// breakpoints as the member-card grid above, so both sections share
  /// identical column centers and the per-column descent lines between
  /// them stay perfectly straight.
  int _columnsFor(double width) => width >= 342 ? 3 : (width >= 224 ? 2 : 1);

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

    // The whole section is laid out inside one LayoutBuilder so the
    // header's per-column spine and the pager share the exact same
    // column centers as the member-card grid above.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        // Columns that actually carry a descent line — the full column
        // set unless the section has fewer members than columns.
        final spineCount = columns < group.members.length
            ? columns
            : group.members.length;
        if (columns != _cardsPerRow) {
          // The page layout changed with the window size; jump back to
          // the first page so the old page position never lingers.
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

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: columns * 220.0 + (columns - 1) * 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Per-column descent lines: straight lines under the
                // cards above, running through this segment and the
                // header's multi-spine straight onto the pager's first
                // card row below.
                SizedBox(
                  height: 22,
                  child: _SpineLines(
                    columns: columns,
                    count: spineCount,
                    beadTop: true,
                  ),
                ),
                // ── Section header ──────────────────────────────────────────
                // A Wrap (not a Row) so the badge/link fall to a second line
                // instead of overflowing when the screen is narrow.
                _SpineBehind(
                  columns: columns,
                  count: spineCount,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  style: const TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '🔥',
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            // Count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blushPaper,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${group.count} ${lang.t(group.subtitleKey)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.rose,
                                ),
                              ),
                            ),
                            // "Tingnan lahat" link — now opens the pinch-zoom tree.
                            GestureDetector(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).push(fadeRoute(const FamilyTreeCanvasPage()));
                              },
                              child: Text(
                                _familyText(
                                  lang,
                                  'family_view_all_grandchildren',
                                  'Tingnan lahat',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.roseDeep,
                                  decoration: TextDecoration
                                      .underline, // hints it's tappable
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // ── Paged avatar rows ───────────────────────────────────────
                // Each apo has its own individual card (see _ApoPageGrid).
                // The pager spans the same constrained width as the grid
                // above, so its columns line up with the per-column descent
                // lines coming down through the header, and it adapts its
                // column count to the available width (see _columnsFor).
                SizedBox(
                  // Tall enough for the branch connector plus two card rows;
                  // grows only to host the new drops.
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
            ),
          ),
        );
      },
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
            // Straight per-column descent onto this page's top card row;
            // drawn per page. No horizontal bus — the descent lines from
            // the header above simply continue down onto the cards, so
            // each column reads as one unbroken straight line. Lines only
            // land on columns that have a card on this page.
            SizedBox(
              height: 28,
              child: _SpineLines(
                columns: cardsPerRow,
                count: cardsPerRow < members.length
                    ? cardsPerRow
                    : members.length,
                beadBottom: true,
              ),
            ),
            for (var r = 0; r < rowsPerPage; r++) ...[
              // Descent lines through the gap above every row after the
              // first: each card continues straight down onto the card
              // beneath it in the same column. A count below the column
              // total (partially-filled row) draws fewer lines; a negative
              // count draws none at all.
              if (r > 0)
                SizedBox(
                  height: rowGap,
                  child: _SpineLines(
                    columns: cardsPerRow,
                    count: members.length - r * cardsPerRow < cardsPerRow
                        ? members.length - r * cardsPerRow
                        : cardsPerRow,
                    beadBottom: true,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < cardsPerRow; c++) ...[
                    if (c > 0 && cardGap > 0) SizedBox(width: cardGap),
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
    final initials = DisplayUtils.initialsOf(member.name);

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
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
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
                      filterQuality: FilterQuality.high,
                      cacheWidth: ImageDecode.width(avatarSize, context),
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
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
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
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
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
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
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

