import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/motion.dart';

/// Small gold diamond that pulses gently, used as a "tap to continue" hint.
/// The system's signature ornament — a 45°-rotated square with a faint gold
/// glow — rather than a plain dot.
class PulsingDiamond extends StatefulWidget {
  const PulsingDiamond({super.key, this.size = 7});

  final double size;

  @override
  State<PulsingDiamond> createState() => _PulsingDiamondState();
}

class _PulsingDiamondState extends State<PulsingDiamond>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Reduced motion: steady full-size diamond instead of the pulse loop.
    if (animationsDisabled()) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.repeat(reverse: true);
    }
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Transform.rotate(
          angle: 0.785398, // 45deg — reads as a small gold diamond
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
