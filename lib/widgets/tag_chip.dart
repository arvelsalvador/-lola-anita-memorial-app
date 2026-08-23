import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Small chip showing a short tag abbreviation. Gold variant for regular
/// tags, rose variant for "+N pa" extras.
class TagChip extends StatelessWidget {
  final String label;

  /// Rose-tinted variant (used for "+N pa" extras).
  final bool rose;

  const TagChip({super.key, required this.label, this.rose = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: rose
            ? AppColors.roseLight.withValues(alpha: 0.6)
            : AppColors.goldLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: rose
              ? AppColors.rose.withValues(alpha: 0.2)
              : AppColors.gold.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: rose ? AppColors.roseDeep : AppColors.warmDeep,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
