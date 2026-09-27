part of 'family_page.dart';

// -- Header --
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
            const _LeafOrnament(),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  lang.t('family_name'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
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
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
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
  const _LeafOrnament();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.spa_outlined, size: 18, color: AppColors.gold);
  }
}

// -- Filter chips --
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

    // One fixed row — never wraps onto a second line and never scrolls.
    // The FittedBox shrink-wraps the row and scales it down on very narrow
    // screens so all three tabs always stay visible on one line, matching
    // the search bar's single fixed field above it.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          key: const Key('family_filter_chips'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterPill(
              label: _familyText(lang, 'family_filter_all', 'Lahat'),
              icon: Icons.grid_view_rounded,
              selected: active == _FamilyFilter.all,
              onTap: () => onSelected(_FamilyFilter.all),
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: _familyText(
                lang,
                'family_filter_direct',
                'Direktang pamilya',
              ),
              icon: Icons.people_outline,
              selected: active == _FamilyFilter.direct,
              onTap: () => onSelected(_FamilyFilter.direct),
            ),
            const SizedBox(width: 10),
            _FilterPill(
              label: _familyText(lang, 'family_filter_apo', 'Mga Apo'),
              icon: Icons.diversity_3_outlined,
              selected: active == _FamilyFilter.apo,
              onTap: () => onSelected(_FamilyFilter.apo),
            ),
          ],
        ),
      ),
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
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
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

// -- Summary + footer --
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
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
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
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
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
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
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

