import 'package:flutter/material.dart';

/// Thin vertical line of dashes, used to separate text from controls.
class DashedVerticalDivider extends StatelessWidget {
  const DashedVerticalDivider({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: height,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
