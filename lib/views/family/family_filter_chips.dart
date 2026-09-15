part of '../family_page.dart';

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
