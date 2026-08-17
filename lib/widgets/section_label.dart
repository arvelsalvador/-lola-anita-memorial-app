import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Section heading used across the Story page ("HER WORDS", "HER
/// JOURNEY", etc.) — spaced caps label with a leading leaf icon and a
/// trailing flourish line, matching the ornamental design direction.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.eco_outlined,
          size: 14,
          color: AppColors.gold.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.sectionLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.rose.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398, // 45deg — reads as a small diamond
          child: Container(
            width: 6,
            height: 6,
            color: AppColors.gold.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
