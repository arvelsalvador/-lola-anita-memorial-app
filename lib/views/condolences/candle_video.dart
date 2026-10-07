import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pure-Flutter candle illustration replicating the memorial badge design:
/// - Soft warm circular ground with 3 concentric halos centered behind the flame
/// - Floating spark speckles
/// - Deep chocolate wood saucer base with bevel highlight rim
/// - White pillar candle with rounded top shoulders, left wax drip, and peach wax pool
/// - Solid dark wick
/// - Golden amber teardrop flame with pure white inner core
/// - Filipino Sampaguita (Arabian jasmine) flowers with 6 white petals and brown centers
/// - Fresh green foliage flanking the base
class CandleVideo extends StatefulWidget {
  final bool lit;
  final VoidCallback onLight;

  const CandleVideo({super.key, required this.lit, required this.onLight});

  @override
  State<CandleVideo> createState() => _CandleVideoState();
}

class _CandleVideoState extends State<CandleVideo>
    with TickerProviderStateMixin {
  late final AnimationController _spark;
  late final AnimationController _flicker;

  @override
  void initState() {
    super.initState();
    _spark = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.lit) {
      _spark.value = 1.0;
      _flicker.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CandleVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.lit && widget.lit) {
      _spark.forward(from: 0);
      _flicker.repeat(reverse: true);
    } else if (oldWidget.lit && !widget.lit) {
      _spark.value = 0;
      _flicker.stop();
    }
  }

  @override
  void dispose() {
    _spark.dispose();
    _flicker.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.lit) {
      _spark.forward(from: 0);
    }
    widget.onLight();
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.lit;
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 250,
        height: 250,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spark, _flicker]),
          builder: (context, _) => CustomPaint(
            size: const Size(250, 250),
            painter: _CandlePainter(
              progress: _spark.value,
              flicker: _flicker.value,
              lit: lit,
            ),
          ),
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final double progress;
  final double flicker;
  final bool lit;

  const _CandlePainter({
    required this.progress,
    required this.flicker,
    required this.lit,
  });

  // Reference art palette
  static const _bgDisc = Color(0xFFFAF7F2);
  static const _haloOuter = Color(0xFFF2EFE9);
  static const _haloMid = Color(0xFFE5DED1);
  static const _haloInner = Color(0xFFD2C5AF);

  static const _sparkDark = Color(0xFF8F7350);
  static const _sparkLight = Color(0xFFD4C7B4);

  static const _leafGreen = Color(0xFF589858);

  static const _saucerBase = Color(0xFF734500);
  static const _saucerBevel = Color(0xFFB9A280);
  static const _saucerRim = Color(0xFF8A5C1F);

  static const _candleBody = Colors.white;
  static const _candleStroke = Color(0xFFCDC6B9);

  static const _waxTop = Color(0xFFF9DCA4);
  static const _waxStroke = Color(0xFFD9BD88);

  static const _wick = Color(0xFF0B0B0B);

  static const _flameOuter = Color(0xFF734500);
  static const _flameInner = Colors.white;

  static const _petalStroke = Color(0xFFC0B9B0);
  static const _flowerPistil = Color(0xFF734500);

  @override
  void paint(Canvas canvas, Size size) {
    // Reference artwork coordinate system: 547 x 537
    const refW = 547.0;
    const refH = 537.0;
    final scale = math.min(size.width / refW, size.height / refH);
    final dx = (size.width - refW * scale) / 2.0;
    final dy = (size.height - refH * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final flameVisible = lit || progress > 0;
    final flickerOffset = (flicker - 0.5) * 3.0;
    final flameScale = lit
        ? (0.95 + flicker * 0.08)
        : (0.15 + progress * 0.85);

    // 1. Large background circle disc
    canvas.drawCircle(
      const Offset(291.5, 280.5),
      251.5,
      Paint()..color = _bgDisc,
    );

    // 2. Three concentric halo circles centered behind the flame
    final haloBreath = lit ? (flicker - 0.5) * 1.5 : 0.0;
    const haloCenter = Offset(291.5, 194.0);

    canvas.drawCircle(
      haloCenter,
      165.0 + haloBreath,
      Paint()..color = _haloOuter,
    );
    canvas.drawCircle(
      haloCenter,
      117.0 + haloBreath * 0.8,
      Paint()..color = _haloMid,
    );
    canvas.drawCircle(
      haloCenter,
      72.0 + haloBreath * 0.6,
      Paint()..color = _haloInner,
    );

    // 3. Floating spark speckles
    final sparkTwinkle = lit ? flickerOffset * 0.3 : 0.0;
    canvas.drawCircle(
      Offset(294.0 + sparkTwinkle, 84.0),
      3.5,
      Paint()..color = _sparkDark,
    );
    canvas.drawCircle(
      Offset(315.0 + sparkTwinkle * 0.8, 83.0),
      2.5,
      Paint()..color = _sparkLight,
    );
    canvas.drawCircle(
      Offset(270.0 - sparkTwinkle, 138.0),
      3.5,
      Paint()..color = _sparkDark,
    );

    // 4. Foliage: green leaves behind flowers and saucer
    _paintFoliage(canvas);

    // 5. Saucer: rich brown wood plate with bevel highlight rim
    _paintSaucer(canvas);

    // 6. Candle pillar body: white cylinder with rounded top shoulders & outline
    _paintCandleBody(canvas);

    // 7. Wax drip on the left side
    _paintWaxDrip(canvas);

    // 8. Melted wax top puddle
    _paintWaxTop(canvas);

    // 9. Black wick
    canvas.drawLine(
      const Offset(291.5, 264.0),
      Offset(291.5 + (flameVisible ? flickerOffset * 0.15 : 0.0), 230.0),
      Paint()
        ..color = _wick
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // 10. Flame (when lit)
    if (flameVisible) {
      _paintFlame(canvas, flickerOffset, flameScale);
    }

    // 11. Sampaguita flowers in front of the base
    _paintFlowers(canvas);

    canvas.restore();
  }

  void _paintFoliage(Canvas canvas) {
    final leafPaint = Paint()..color = _leafGreen;
    const cx = 291.5;

    // Left leaves: (tipX, tipY, baseX, baseY, width)
    const leavesLeft = [
      (174.0, 420.0, 195.0, 455.0, 24.0),
      (136.0, 449.0, 175.0, 465.0, 22.0),
      (145.0, 475.0, 175.0, 478.0, 18.0),
    ];

    for (final leaf in leavesLeft) {
      _drawLeaf(
        canvas,
        Offset(leaf.$3, leaf.$4),
        Offset(leaf.$1, leaf.$2),
        leaf.$5,
        leafPaint,
      );
      // Mirrored on the right
      _drawLeaf(
        canvas,
        Offset(2 * cx - leaf.$3, leaf.$4),
        Offset(2 * cx - leaf.$1, leaf.$2),
        leaf.$5,
        leafPaint,
      );
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    Offset tip,
    double width,
    Paint paint,
  ) {
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final nx = -dy / len * (width / 2.0);
    final ny = dx / len * (width / 2.0);
    final mid = Offset((base.dx + tip.dx) / 2.0, (base.dy + tip.dy) / 2.0);

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + (mid.dx - base.dx) * 0.5 + nx,
        base.dy + (mid.dy - base.dy) * 0.5 + ny,
        tip.dx - (tip.dx - mid.dx) * 0.5 + nx * 0.7,
        tip.dy - (tip.dy - mid.dy) * 0.5 + ny * 0.7,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        tip.dx - (tip.dx - mid.dx) * 0.5 - nx * 0.7,
        tip.dy - (tip.dy - mid.dy) * 0.5 - ny * 0.7,
        base.dx + (mid.dx - base.dx) * 0.5 - nx,
        base.dy + (mid.dy - base.dy) * 0.5 - ny,
        base.dx,
        base.dy,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  void _paintSaucer(Canvas canvas) {
    const saucerCenter = Offset(291.5, 462.0);
    final saucerRect = Rect.fromCenter(
      center: saucerCenter,
      width: 208.0,
      height: 54.0,
    );

    // Deep chocolate wood base
    canvas.drawOval(saucerRect, Paint()..color = _saucerBase);

    // Top bevel highlight arc
    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(291.5, 458.0),
        width: 196.0,
        height: 42.0,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _saucerBevel,
    );

    // Outer rim outline
    canvas.drawOval(
      saucerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _saucerRim,
    );
  }

  void _paintCandleBody(Canvas canvas) {
    // White pillar with rounded top shoulders
    final bodyPath = Path()
      ..moveTo(232.0, 435.0)
      ..lineTo(232.0, 274.0)
      ..arcToPoint(
        const Offset(246.0, 260.0),
        radius: const Radius.circular(14.0),
      )
      ..lineTo(337.0, 260.0)
      ..arcToPoint(
        const Offset(351.0, 274.0),
        radius: const Radius.circular(14.0),
      )
      ..lineTo(351.0, 435.0)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = _candleBody);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _candleStroke,
    );
  }

  void _paintWaxDrip(Canvas canvas) {
    final dripPath = Path()
      ..moveTo(253.0, 260.0)
      ..lineTo(253.0, 306.0)
      ..arcToPoint(
        const Offset(273.0, 306.0),
        radius: const Radius.circular(10.0),
        clockwise: false,
      )
      ..lineTo(273.0, 260.0)
      ..close();

    canvas.drawPath(dripPath, Paint()..color = _candleBody);
    canvas.drawPath(
      dripPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _candleStroke,
    );
  }

  void _paintWaxTop(Canvas canvas) {
    final waxRect = Rect.fromCenter(
      center: const Offset(291.5, 260.0),
      width: 119.0,
      height: 28.0,
    );

    canvas.drawOval(waxRect, Paint()..color = _waxTop);
    canvas.drawOval(
      waxRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _waxStroke,
    );
  }

  void _paintFlame(Canvas canvas, double flickerOffset, double flameScale) {
    final fx = 291.5 + flickerOffset * 0.4;
    final topY = 132.0 + (1.0 - flameScale) * 35.0;
    const baseY = 232.0;
    final hw = 25.5 * flameScale;

    // Outer amber teardrop flame
    final outerFlame = Path()
      ..moveTo(fx, topY)
      ..cubicTo(
        fx - hw * 1.05,
        topY + (baseY - topY) * 0.35,
        fx - hw * 1.05,
        baseY - 15.0,
        291.5,
        baseY,
      )
      ..cubicTo(
        fx + hw * 1.05,
        baseY - 15.0,
        fx + hw * 1.05,
        topY + (baseY - topY) * 0.35,
        fx,
        topY,
      )
      ..close();

    canvas.drawPath(outerFlame, Paint()..color = _flameOuter);

    // Inner pure white teardrop flame core
    final coreTopY = 176.0 + (1.0 - flameScale) * 20.0;
    const coreBaseY = 224.0;
    final chw = 11.5 * flameScale;

    final innerFlame = Path()
      ..moveTo(fx, coreTopY)
      ..cubicTo(
        fx - chw * 1.05,
        coreTopY + (coreBaseY - coreTopY) * 0.35,
        fx - chw * 1.05,
        coreBaseY - 8.0,
        291.5,
        coreBaseY,
      )
      ..cubicTo(
        fx + chw * 1.05,
        coreBaseY - 8.0,
        fx + chw * 1.05,
        coreTopY + (coreBaseY - coreTopY) * 0.35,
        fx,
        coreTopY,
      )
      ..close();

    canvas.drawPath(innerFlame, Paint()..color = _flameInner);
  }

  void _paintFlowers(Canvas canvas) {
    // 4 Sampaguita flowers:
    // Inner Left, Outer Left, Inner Right, Outer Right
    _drawFlower(canvas, const Offset(195.0, 463.0));
    _drawFlower(canvas, const Offset(163.0, 478.0));
    _drawFlower(canvas, const Offset(388.0, 463.0));
    _drawFlower(canvas, const Offset(420.0, 478.0));
  }

  void _drawFlower(Canvas canvas, Offset center) {
    final petalFill = Paint()..color = Colors.white;
    final petalStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _petalStroke;
    final pistilPaint = Paint()..color = _flowerPistil;

    // 6 pointed/oval sampaguita petals
    for (var i = 0; i < 6; i++) {
      final a = i * (math.pi / 3.0) - (math.pi / 2.0);
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      final nx = -sinA;
      final ny = cosA;

      const rStart = 6.0;
      const rTip = 32.0;

      final p0 = Offset(center.dx + cosA * rStart, center.dy + sinA * rStart);
      final tip = Offset(center.dx + cosA * rTip, center.dy + sinA * rTip);

      final c1 = Offset(
        center.dx + cosA * 14.0 + nx * 6.5,
        center.dy + sinA * 14.0 + ny * 6.5,
      );
      final c2 = Offset(
        center.dx + cosA * 26.0 + nx * 4.5,
        center.dy + sinA * 26.0 + ny * 4.5,
      );
      final c3 = Offset(
        center.dx + cosA * 26.0 - nx * 4.5,
        center.dy + sinA * 26.0 - ny * 4.5,
      );
      final c4 = Offset(
        center.dx + cosA * 14.0 - nx * 6.5,
        center.dy + sinA * 14.0 - ny * 6.5,
      );

      final petalPath = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy)
        ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, p0.dx, p0.dy)
        ..close();

      canvas.drawPath(petalPath, petalFill);
      canvas.drawPath(petalPath, petalStroke);
    }

    // Brown center pistil dot
    canvas.drawCircle(center, 6.5, pistilPaint);
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flicker != flicker ||
        oldDelegate.lit != lit;
  }
}
