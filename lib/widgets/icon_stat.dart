import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Icon over a small label, used inside stats cards.
class IconStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const IconStat({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: AppColors.gold),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.warmMid,
          ),
        ),
      ],
    );
  }
}
