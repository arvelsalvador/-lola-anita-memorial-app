import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Circular icon button on a translucent (or filled) dark chip, used for
/// slideshow controls.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.white : Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: size,
            color: filled ? AppColors.warmDark : Colors.white,
          ),
        ),
      ),
    );
  }
}
