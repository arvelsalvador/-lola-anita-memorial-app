import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Circular rose-to-gold gradient badge with a gold hairline ring, used
/// for initials avatars and photo-like thumbnail placeholders.
class GradientAvatar extends StatelessWidget {
  final double size;

  /// When set, shows an icon instead of initials text.
  final IconData? icon;

  /// Initials text shown when [icon] is null.
  final String? initials;

  final double iconSize;
  final Color iconColor;

  /// Opacity of the goldLight end of the gradient.
  final double gradientEndAlpha;

  final double borderAlpha;
  final double borderWidth;
  final double initialsSize;

  const GradientAvatar({
    super.key,
    this.size = 40,
    this.icon,
    this.initials,
    this.iconSize = 20,
    this.iconColor = AppColors.roseDeep,
    this.gradientEndAlpha = 0.6,
    this.borderAlpha = 0.2,
    this.borderWidth = 0.6,
    this.initialsSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.roseLight,
            AppColors.goldLight.withValues(alpha: gradientEndAlpha),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: borderAlpha),
          width: borderWidth,
        ),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: iconSize, color: iconColor)
            : Text(
                initials ?? '',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: initialsSize,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
      ),
    );
  }
}
