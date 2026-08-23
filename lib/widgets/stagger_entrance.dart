import 'package:flutter/material.dart';

/// Staggered fade + rise entrance: fades a child in over the [begin]-[end]
/// slice of a shared parent animation, optionally rising from [offset].
class StaggerEntrance extends StatelessWidget {
  final Animation<double> controller;
  final double begin;
  final double end;
  final Offset offset;
  final Curve curve;
  final Widget child;

  const StaggerEntrance({
    super.key,
    required this.controller,
    required this.begin,
    required this.end,
    this.offset = Offset.zero,
    this.curve = Curves.easeOut,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: curve),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: offset * (1 - v), child: child),
        );
      },
      child: child,
    );
  }
}
