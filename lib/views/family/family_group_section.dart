part of '../family_page.dart';

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
