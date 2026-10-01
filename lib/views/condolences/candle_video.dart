import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Pure-Flutter candle illustration with a short lighting animation.
/// No native video decoder or texture is used.
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
      duration: const Duration(milliseconds: 720),
    );
    if (widget.lit) {
      _spark.value = 1;
      _flicker.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CandleVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.lit && widget.lit) {
      _spark.forward(from: 0);
      _flicker.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spark.dispose();
    _flicker.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.lit) _spark.forward(from: 0);
    widget.onLight();
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.lit;
    return SizedBox(
      width: 240,
      height: 224,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _Halo(size: 224, alpha: lit ? 0.5 : 0.18),
          Positioned(top: 8, child: _Halo(size: 208, alpha: lit ? 0.5 : 0.3)),
          Positioned(
            top: 12,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper.withValues(alpha: 0.72),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(
                        alpha: lit ? 0.42 : 0.15,
                      ),
                      blurRadius: lit ? 34 : 14,
                      spreadRadius: lit ? 2 : 0,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spark, _flicker]),
                    builder: (context, _) => CustomPaint(
                      painter: _CandlePainter(
                        progress: _spark.value,
                        flicker: _flicker.value,
                        lit: lit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  final double size;
  final double alpha;

  const _Halo({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: alpha),
          width: 1.1,
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

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final flameVisible = lit || progress > 0;
    final flickerOffset = (flicker - 0.5) * 4;
    final flameScale = lit ? 0.92 + flicker * 0.12 : 0.72 + progress * 0.28;

    // Warm ivory wash + soft halo behind the candle, like the reference
    // medallion: cream ground with light pooling around the pillar.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.petalWhite, AppColors.cream],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawCircle(
      Offset(centerX + flickerOffset * 0.4, 98),
      lit ? 72 : 60,
      Paint()
        ..color = AppColors.flameGlow.withValues(alpha: lit ? 0.42 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    if (flameVisible) {
      final glowAlpha = lit ? 0.24 : (1 - progress).clamp(0.0, 1.0) * 0.2;
      canvas.drawCircle(
        Offset(centerX + flickerOffset, 76),
        lit ? 54 + flicker * 8 : 48,
        Paint()
          ..color = AppColors.flameGlow.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Sage leaf clusters sit behind the candle base (always visible,
    // lit or unlit) so the florals read as a wreath, not a reward.
    _paintLeaves(canvas, centerX);

    // Wooden saucer under the pillar, matching the reference base.
    final pedestalPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.woodLight, AppColors.woodDeep],
      ).createShader(Rect.fromLTWH(centerX - 44, 156, 88, 15));
    // Soft contact shadow first so the saucer lifts off the paper.
    canvas.drawOval(
      Rect.fromLTWH(centerX - 46, 164, 92, 10),
      Paint()
        ..color = AppColors.warmDark.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 44, 156, 88, 14),
        const Radius.circular(7),
      ),
      pedestalPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 44, 156, 88, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    final waxRect = Rect.fromLTWH(centerX - 30, 91, 60, 70);
    final waxPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.waxDeep, AppColors.waxLight, AppColors.waxShade],
        stops: [0, 0.42, 1],
      ).createShader(waxRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(waxRect, const Radius.circular(9)),
      waxPaint,
    );

    final waxTop = Path()
      ..moveTo(centerX - 30, 98)
      ..cubicTo(centerX - 20, 88, centerX - 9, 96, centerX, 91)
      ..cubicTo(centerX + 10, 86, centerX + 19, 96, centerX + 30, 91)
      ..lineTo(centerX + 30, 105)
      ..lineTo(centerX - 30, 105)
      ..close();
    canvas.drawPath(waxTop, Paint()..color = AppColors.waxLight);

    final dripPaint = Paint()..color = AppColors.waxDrip;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 21, 98, 8, 24),
        const Radius.circular(4),
      ),
      dripPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 13, 96, 7, 17),
        const Radius.circular(3.5),
      ),
      dripPaint,
    );

    final stripePaint = Paint()
      ..color = AppColors.medallionGoldDeep.withValues(alpha: 0.28)
      ..strokeWidth = 1.4;
    for (var stripeIndex = -1; stripeIndex < 2; stripeIndex++) {
      final stripeX = centerX + stripeIndex * 20.0;
      canvas.drawLine(Offset(stripeX, 117), Offset(stripeX, 151), stripePaint);
    }

    // White memorial flowers in front of the base (always visible).
    _paintFlowers(canvas, centerX);

    canvas.drawLine(
      Offset(centerX, 94),
      Offset(centerX + flickerOffset * 0.3, 80),
      Paint()
        ..color = AppColors.wickBrown
        ..strokeWidth = 2.2,
    );

    if (flameVisible) {
      final flameCenter = Offset(centerX + flickerOffset, 68);
      final flamePath = Path()
        ..moveTo(flameCenter.dx, flameCenter.dy - 30 * flameScale)
        ..cubicTo(
          flameCenter.dx - 23 * flameScale,
          flameCenter.dy - 12,
          flameCenter.dx - 17 * flameScale,
          flameCenter.dy + 13,
          flameCenter.dx,
          flameCenter.dy + 19,
        )
        ..cubicTo(
          flameCenter.dx + 17 * flameScale,
          flameCenter.dy + 13,
          flameCenter.dx + 23 * flameScale,
          flameCenter.dy - 12,
          flameCenter.dx,
          flameCenter.dy - 30 * flameScale,
        )
        ..close();
      canvas.drawPath(flamePath, Paint()..color = AppColors.flameAmber);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(flameCenter.dx, flameCenter.dy + 4),
          width: 15 * flameScale,
          height: 27 * flameScale,
        ),
        Paint()..color = AppColors.flameInner,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(flameCenter.dx, flameCenter.dy + 8),
          width: 7 * flameScale,
          height: 16 * flameScale,
        ),
        Paint()..color = AppColors.flameCore,
      );
    }

    if (!lit && progress < 1) {
      for (var sparkIndex = 0; sparkIndex < 8; sparkIndex++) {
        final seed = (sparkIndex * 0.41) % 1.0;
        final rise = ((progress * 1.2 + seed) % 1.0) * 50;
        final sparkAlpha = (1 - progress) * (0.3 + seed * 0.5);
        canvas.drawCircle(
          Offset(centerX + (seed - 0.5) * 40, 61 - rise),
          1.2 + sparkIndex % 2,
          Paint()..color = AppColors.flameGold.withValues(alpha: sparkAlpha),
        );
      }
    }
  }

  /// Sage leaves fanning out from behind the candle base, mirrored
  /// left/right like the reference wreath.
  void _paintLeaves(Canvas canvas, double cx) {
    // (dx from candle center, dy, length, width, color)
    const List<(double, double, double, double, double, double, int)>
        leaves = [
      (-30.0, 148.0, -56.0, 150.0, 26.0, 11.0, 0), // left outer
      (-30.0, 144.0, -54.0, 136.0, 26.0, 11.0, 1), // left mid
      (-28.0, 140.0, -44.0, 122.0, 24.0, 10.0, 0), // left upper
      (-26.0, 138.0, -32.0, 120.0, 20.0, 9.0, 1), // left bud stem
      (30.0, 148.0, 56.0, 150.0, 26.0, 11.0, 0), // right outer
      (30.0, 144.0, 54.0, 136.0, 26.0, 11.0, 1), // right mid
      (28.0, 140.0, 44.0, 122.0, 24.0, 10.0, 0), // right upper
      (26.0, 138.0, 32.0, 120.0, 20.0, 9.0, 1), // right bud stem
    ];
    for (final leaf in leaves) {
      final base = Offset(cx + leaf.$1, leaf.$2);
      final tip = Offset(cx + leaf.$3, leaf.$4);
      final color = leaf.$7 == 0 ? AppColors.leafSage : AppColors.leafDeep;
      _leaf(canvas, base, tip, leaf.$5, leaf.$6, color);
    }
  }

  void _leaf(
    Canvas canvas,
    Offset base,
    Offset tip,
    double length,
    double width,
    Color color,
  ) {
    final angle = math.atan2(tip.dy - base.dy, tip.dx - base.dx);
    final center = Offset(
      (base.dx + tip.dx) / 2,
      (base.dy + tip.dy) / 2,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: width,
      ),
      Paint()..color = color,
    );
    // Pale center vein.
    canvas.drawLine(
      Offset(-length / 2 + 3, 0),
      Offset(length / 2 - 3, 0),
      Paint()
        ..color = AppColors.leafPale.withValues(alpha: 0.7)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  /// Two white 5-petal flowers + two small buds at the candle foot.
  void _paintFlowers(Canvas canvas, double cx) {
    // Small buds peeking from behind the pillar.
    _flower(canvas, Offset(cx - 27, 132), 7);
    _flower(canvas, Offset(cx + 27, 132), 7);
    // Main blooms in front of the saucer.
    _flower(canvas, Offset(cx - 40, 144), 12.5);
    _flower(canvas, Offset(cx + 40, 144), 12.5);
  }

  void _flower(Canvas canvas, Offset center, double radius) {
    final petalOffset = radius * 0.78;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final petalCenter = Offset(
        center.dx + math.cos(a) * petalOffset,
        center.dy + math.sin(a) * petalOffset,
      );
      // Soft drop shadow so petals lift off the paper.
      canvas.drawCircle(
        Offset(petalCenter.dx + 0.8, petalCenter.dy + 1.2),
        radius * 0.62,
        Paint()..color = AppColors.warmDark.withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        petalCenter,
        radius * 0.62,
        Paint()..color = AppColors.petalWhite,
      );
      canvas.drawCircle(
        petalCenter,
        radius * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.petalShade,
      );
    }
    // Golden heart.
    canvas.drawCircle(
      center,
      radius * 0.30,
      Paint()..color = AppColors.flowerHeart,
    );
    canvas.drawCircle(
      center,
      radius * 0.14,
      Paint()..color = AppColors.amber.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flicker != flicker ||
        oldDelegate.lit != lit;
  }
}
