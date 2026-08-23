import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Small gold dot that pulses gently, used as a "tap to continue" hint.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
