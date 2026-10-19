import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Circular icon button on a translucent (or filled) dark chip, used for
/// slideshow controls and the admin page header.
///
/// Callers that need their own chrome (a fixed 44px tap target, a paper
/// surface) override [buttonSize], [backgroundColor] and [foregroundColor]
/// instead of copying the Material/InkWell shell.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  /// When set, the tap target is a square of this size instead of the
  /// icon plus its default 11px padding.
  final double? buttonSize;

  /// Optional surface override. Defaults to the slideshow treatment
  /// (translucent paper, or [AppColors.paper] when [filled]).
  final Color? backgroundColor;

  /// Optional icon color override. Defaults to [AppColors.paper], or
  /// [AppColors.warmDark] when [filled].
  final Color? foregroundColor;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.filled = false,
    this.buttonSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        backgroundColor ??
        (filled ? AppColors.paper : AppColors.paper.withValues(alpha: 0.14));
    final ink =
        foregroundColor ?? (filled ? AppColors.warmDark : AppColors.paper);
    final glyph = Icon(icon, size: size, color: ink);

    return Material(
      color: surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: buttonSize == null
            ? Padding(padding: const EdgeInsets.all(11), child: glyph)
            : SizedBox(width: buttonSize, height: buttonSize, child: glyph),
      ),
    );
  }
}
