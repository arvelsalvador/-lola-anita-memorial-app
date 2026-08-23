import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Breathing golden halo wrapped around a child — draws the eye to
/// featured elements. All instances share one parent-driven animation so
/// every glow moves in perfect sync.
class GlowPulse extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const GlowPulse({super.key, required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        // Halo always stays larger than the 66px circle (76 -> 102) and its
        // rim keeps a strong alpha while breathing, so the pulse is clearly
        // visible. The box is a constant 110x110 and all motion is a
        // paint-only transform, so the strip never re-layouts and the
        // animation stays smooth.
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -22,
              top: -22,
              width: 110,
              height: 110,
              child: Transform.scale(
                scale: (76 + 26 * t) / 110,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.0),
                        AppColors.gold.withValues(alpha: 0.75 - 0.3 * t),
                        AppColors.gold.withValues(alpha: 0.0),
                      ],
                      stops: const [0.6, 0.82, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Transform.scale(scale: 1 + 0.04 * t, child: child),
          ],
        );
      },
      child: child,
    );
  }
}
