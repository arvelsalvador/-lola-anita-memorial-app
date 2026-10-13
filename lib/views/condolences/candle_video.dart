import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nita/core/constants/app_constants.dart';

/// Pure-Flutter candle illustration for the memorial action: a quiet modern
/// medallion, softly shaded candle, warm animated flame, and small flowers.
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
        width: 238,
        height: 238,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spark, _flicker]),
          builder: (context, _) => CustomPaint(
            size: const Size(238, 238),
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

  static const _sparkDark = AppColors.goldInk;
  static const _sparkLight = AppColors.goldLight;

  static const _leafGreen = AppColors.leafSage;
  static const _leafDeep = AppColors.leafDeep;

  static const _saucerBase = AppColors.woodDeep;
  static const _saucerRim = AppColors.woodLight;

  static const _candleStroke = AppColors.waxShade;
  static const _waxTop = AppColors.goldLight;
  static const _waxStroke = AppColors.gold;

  static const _wick = AppColors.warmDeep;

  static const _flameOuter = AppColors.flameAmber;
  static const _flameMid = AppColors.flameGold;
  static const _flameInner = AppColors.flameInner;

  static const _petalStroke = AppColors.petalShade;
  static const _flowerPistil = AppColors.flowerHeart;

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

    const discCenter = Offset(291.5, 280.5);
    final discRect = Rect.fromCircle(center: discCenter, radius: 251.5);

    canvas.drawCircle(
      discCenter.translate(0, 12),
      232,
      Paint()
        ..color = AppColors.warmDark.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    canvas.drawCircle(
      discCenter,
      251.5,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.18, -0.24),
          radius: 0.95,
          colors: [
            AppColors.paper,
            AppColors.cream,
            AppColors.goldLight,
          ],
          stops: [0.0, 0.70, 1.0],
        ).createShader(discRect),
    );
    canvas.drawCircle(
      discCenter,
      249.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = AppColors.gold.withValues(alpha: 0.18),
    );

    final haloBreath = lit ? (flicker - 0.5) * 1.5 : 0.0;
    const haloCenter = Offset(291.5, 194.0);
    for (final ring in const [
      (166.0, 0.12, 1.0),
      (116.0, 0.18, 0.8),
      (70.0, 0.24, 0.6),
    ]) {
      canvas.drawCircle(
        haloCenter,
        ring.$1 + haloBreath * ring.$3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.$1 > 150 ? 10 : 8
          ..color = AppColors.gold.withValues(alpha: ring.$2),
      );
    }

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
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_leafGreen, _leafDeep],
      ).createShader(const Rect.fromLTWH(120, 410, 340, 90));
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

    canvas.drawOval(
      saucerRect.shift(const Offset(0, 7)),
      Paint()
        ..color = AppColors.warmDark.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(
      saucerRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.woodLight, _saucerBase],
        ).createShader(saucerRect),
    );

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
        ..strokeWidth = 2
        ..color = AppColors.paper.withValues(alpha: 0.45),
    );

    canvas.drawOval(
      saucerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _saucerRim.withValues(alpha: 0.65),
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

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.petalWhite,
            AppColors.waxLight,
            AppColors.handShade,
          ],
          stops: [0.0, 0.66, 1.0],
        ).createShader(const Rect.fromLTWH(232, 260, 119, 175)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(333, 272)
        ..lineTo(333, 424),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = AppColors.warmDark.withValues(alpha: 0.035),
    );
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

    canvas.drawPath(dripPath, Paint()..color = AppColors.waxLight);
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

    canvas.drawOval(
      waxRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.candleGlow, _waxTop],
        ).createShader(waxRect),
    );
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

    canvas.drawPath(
      outerFlame,
      Paint()
        ..color = AppColors.flameGlow.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      outerFlame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.flameEmber,
            _flameOuter,
            _flameMid,
          ],
        ).createShader(Rect.fromLTWH(fx - hw, topY, hw * 2, baseY - topY)),
    );

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

    canvas.drawPath(
      innerFlame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.flameCore, _flameInner],
        ).createShader(
          Rect.fromLTWH(fx - chw, coreTopY, chw * 2, coreBaseY - coreTopY),
        ),
    );
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
