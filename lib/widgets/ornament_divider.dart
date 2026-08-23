import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Centerpiece of an [OrnamentDivider]: a small gold diamond (default),
/// a dot, or a rotated leaf.
enum OrnamentCenter { diamond, dot, leaf }

/// Thin gold lines flanking a small centered ornament — the app's
/// signature decorative divider, used under page headers, in the hero,
/// and inside quote cards.
class OrnamentDivider extends StatelessWidget {
  /// Fixed length for the two flanking lines; when null they expand to
  /// fill the available width.
  final double? lineLength;

  /// Horizontal gap between the lines and the centerpiece.
  final double gap;

  /// Opacity of the flanking gold lines.
  final double lineAlpha;

  /// Which ornament sits in the middle.
  final OrnamentCenter center;

  const OrnamentDivider({
    super.key,
    this.lineLength,
    this.gap = 10,
    this.lineAlpha = 0.5,
    this.center = OrnamentCenter.diamond,
  });

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: lineLength,
      height: 1,
      color: AppColors.gold.withValues(alpha: lineAlpha),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: switch (center) {
            OrnamentCenter.diamond => Transform.rotate(
              angle: 0.785398, // 45deg — reads as a small diamond
              child: Container(
                width: 6,
                height: 6,
                color: AppColors.gold.withValues(alpha: 0.7),
              ),
            ),
            OrnamentCenter.dot => Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
            ),
            OrnamentCenter.leaf => Transform.rotate(
              angle: 1.5708, // 90deg — reads as an upright leaf
              child: const Icon(
                Icons.eco_rounded,
                size: 14,
                color: AppColors.gold,
              ),
            ),
          },
        ),
        line,
      ],
    );
  }
}
