import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Thin dot used to separate meta items.
class Dot extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const Dot({
    super.key,
    this.size = 3,
    this.color = AppColors.muted,
    this.alpha = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}
