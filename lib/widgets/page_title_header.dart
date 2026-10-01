import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Shared centered page title, copied from the Family page header
/// ([FamilyPageHeader]): Lora title, upright subtitle, and gold rule.
/// Used by the Words, Pakikiramay, and Gallery tabs so every page reads
/// as one design system.
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 31,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.warmDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lora',
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
