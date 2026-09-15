part of '../family_page.dart';

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
