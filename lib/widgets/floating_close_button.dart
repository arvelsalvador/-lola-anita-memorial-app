import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Circular dark close button for full-screen overlays.
class FloatingCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.viewerBackground.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.close_rounded, size: 22, color: AppColors.paper),
        ),
      ),
    );
  }
}
