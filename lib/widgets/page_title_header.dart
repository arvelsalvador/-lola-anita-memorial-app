import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Shared centered page title, copied from the Family page header
/// ([FamilyPageHeader]): flanking leaf ornaments, Playfair title, italic
/// subtitle, gold rule, and leaf divider. Used by the Words, Pakikiramay,
/// and Gallery tabs so every page reads as one design system.
class PageTitleHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageTitleHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
                  title,
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
          subtitle,
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
  const _LeafOrnament();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.spa_outlined, size: 18, color: AppColors.gold);
  }
}
