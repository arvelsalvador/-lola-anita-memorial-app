import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// The app's standard white rounded card shell: soft fill, a hairline
/// tinted border, and a warm shadow. Parameterized so every card in the
/// app shares one recipe instead of hand-rolled duplicates.
class OrnamentalCard extends StatelessWidget {
  final double radius;
  final Color? fill;
  final Color borderColor;
  final double borderAlpha;
  final double borderWidth;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final Widget child;

  const OrnamentalCard({
    super.key,
    this.radius = 16,
    this.fill = AppColors.white,
    this.borderColor = AppColors.gold,
    this.borderAlpha = 0.2,
    this.borderWidth = 0.6,
    this.shadowOpacity = 0.06,
    this.shadowBlur = 12,
    this.shadowOffset = const Offset(0, 4),
    this.padding = EdgeInsets.zero,
    this.margin,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor.withValues(alpha: borderAlpha),
          width: borderWidth,
        ),
        boxShadow: [
          if (shadowOpacity > 0)
            BoxShadow(
              color: AppColors.warmDark.withValues(alpha: shadowOpacity),
              blurRadius: shadowBlur,
              offset: shadowOffset,
            ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
