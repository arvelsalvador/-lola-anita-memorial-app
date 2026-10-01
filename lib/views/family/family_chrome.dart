part of 'family_page.dart';

// -- Header --
/// "Pamilya" title, upright subtitle, and gold rule underneath —
/// matches the screenshot's simple centered header (no ornaments).
class FamilyPageHeader extends StatelessWidget {
  const FamilyPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            lang.t('family_name'),
            textAlign: TextAlign.center,
            style: AppTextStyles.homeContent.copyWith(
              fontSize: 31,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.warmDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lang.t('family_subtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.homeContent.copyWith(
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
      ],
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
      borderRadius: BorderRadius.circular(12),
      child: OrnamentalCard(
        radius: 12,
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
                    style: AppTextStyles.homeContent.copyWith(
                      fontSize: 12.5,
                      color: AppColors.roseDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${_familyText(lang, 'family_members_word', 'miyembro')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeContent.copyWith(
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
      radius: 12,
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
              style: AppTextStyles.homeContent.copyWith(
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

