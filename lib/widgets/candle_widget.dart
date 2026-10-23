import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nita/core/constants/app_constants.dart';

/// The Huling Araw candle: a wax pillar with drips on a golden saucer.
///
/// Before it is lit, a wisp of smoke curls above the wick and dissolves as
/// the flame catches; once lit, the flame breathes with two layered flickers
/// and a warm halo blooms around it.
///
/// This is the same artwork and animation used by the Gallery's candle gate.
class CandleWidget extends StatefulWidget {
  final bool isLit;
  final Size size;
  final VoidCallback? onTap;

  const CandleWidget({
    super.key,
    required this.isLit,
    this.size = const Size(150, 188),
    this.onTap,
  });

  @override
  State<CandleWidget> createState() => _CandleWidgetState();
}

class _CandleWidgetState extends State<CandleWidget>
    with TickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Wraps _bloom in an easing curve so the warm light feels like it's
  // catching and flaring, rather than growing at a flat, linear rate.
  late final Animation<double> _bloomCurve = CurvedAnimation(
    parent: _bloom,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // Already lit on mount: start at the settled lit state instead of
    // replaying the ignition every time this widget remounts.
    if (widget.isLit) _bloom.value = 1;
  }

  @override
  void didUpdateWidget(covariant CandleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLit && widget.isLit) {
      _bloom.forward(from: 0);
    } else if (oldWidget.isLit && !widget.isLit) {
      _bloom.value = 0;
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _bloom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candle = RepaintBoundary(
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flicker, _bloomCurve]),
          builder: (context, _) {
            // Two overlapping sine waves at different speeds instead of one
            // clean wave — this is what makes the flame's sway look organic
            // instead of metronomic.
            final wobble =
                math.sin(_flicker.value * 2 * math.pi) * 0.7 +
                math.sin(_flicker.value * 5 * math.pi + 1.1) * 0.3;
            return CustomPaint(
              size: widget.size,
              painter: _CandlePainter(
                lit: widget.isLit,
                bloom: _bloomCurve.value,
                flicker: wobble,
              ),
            );
          },
        ),
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return candle;
    return GestureDetector(onTap: onTap, child: candle);
  }
}

/// Candle with wax drips on a small golden saucer. Before it is lit, a wisp
/// of smoke curls above the wick and dissolves as the flame catches; once
/// lit, the flame breathes with two layered flickers and a warm halo blooms
/// around it.
class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.lit,
    required this.bloom,
    required this.flicker,
  });

  final bool lit;
  final double bloom;
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final waxTop = size.height * 0.58;
    final waxBottom = size.height * 0.86;
    final waxWidth = size.width * 0.2;

    // Ground shadow under the saucer.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.955),
        width: waxWidth * 2.1,
        height: 9,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Golden saucer.
    final saucer = Rect.fromCenter(
      center: Offset(cx, size.height * 0.945),
      width: waxWidth * 1.85,
      height: 11,
    );
    canvas.drawOval(
      saucer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.medallionGoldLight, AppColors.medallionGoldDeep],
        ).createShader(saucer),
    );
    canvas.drawOval(saucer.deflate(2), Paint()..color = AppColors.medallionInk);

    // Warm halo blooming around the flame when lit.
    if (lit) {
      final glowCenter = Offset(cx, waxTop - 26);
      final glowRadius = size.height * (0.42 + 0.04 * flicker + 0.16 * bloom);
      canvas.drawCircle(
        glowCenter,
        glowRadius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  AppColors.flameGold.withValues(alpha: 0.55),
                  AppColors.flameGold.withValues(alpha: 0.0),
                ],
              ).createShader(
                Rect.fromCircle(center: glowCenter, radius: glowRadius),
              ),
      );
    }

    // A wisp of smoke that fades out as the flame's bloom fades in, instead
    // of vanishing abruptly the instant the candle is lit.
    final smokeOpacity = lit ? (1 - bloom).clamp(0.0, 1.0) : 1.0;
    if (smokeOpacity > 0) {
      final smokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12 * smokeOpacity)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(cx, waxTop - 10)
        ..quadraticBezierTo(cx + 3 * flicker, waxTop - 22, cx - 2, waxTop - 32)
        ..quadraticBezierTo(
          cx - 6 * flicker.abs(),
          waxTop - 42,
          cx + 1,
          waxTop - 50,
        );
      canvas.drawPath(path, smokePaint);
    }

    // Flame: outer amber, middle gold, bright core. Two layered flickers
    // make the light feel alive.
    if (lit) {
      final flameBase = Offset(cx, waxTop - 4);
      final fh =
          size.height *
          0.17 *
          (1 + 0.04 * flicker + 0.05 * math.sin(flicker * 3 + 1.3));
      final fw = size.height * 0.075 * (1 + 0.05 * flicker);
      final outerRect = Rect.fromLTWH(
        flameBase.dx - fw,
        flameBase.dy - fh,
        fw * 2,
        fh,
      );
      canvas.drawPath(
        _flamePath(flameBase, fh, fw),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.flameCore,
              AppColors.flameAmber,
              AppColors.flameEmber,
            ],
          ).createShader(outerRect),
      );
      canvas.drawPath(
        _flamePath(flameBase, fh * 0.62, fw * 0.58),
        Paint()..color = AppColors.flameGlow,
      );
      canvas.drawPath(
        _flamePath(flameBase, fh * 0.3, fw * 0.3),
        Paint()..color = AppColors.flameInner,
      );
    }

    // Wick.
    canvas.drawLine(
      Offset(cx, waxTop - 2),
      Offset(cx, waxTop + 7),
      Paint()
        ..color = AppColors.wickBrown
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Wax body with a soft vertical shading.
    final waxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - waxWidth / 2, waxTop, waxWidth, waxBottom - waxTop),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      waxRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.waxShade, AppColors.waxLight, AppColors.waxDeep],
          stops: [0.0, 0.5, 1.0],
        ).createShader(waxRect.outerRect),
    );

    // Melted rim.
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - waxWidth * 0.62, waxTop - 3, waxWidth * 1.24, 9),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(
      rimRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.handPaper, AppColors.handShade],
        ).createShader(rimRect.outerRect),
    );

    // Wax drips hanging from the rim.
    final dripPaint = Paint()..color = AppColors.waxDrip;
    const drips = [
      (dx: 0.52, len: 0.12),
      (dx: 0.62, len: 0.07),
      (dx: 0.44, len: 0.16),
      (dx: 0.55, len: 0.05),
    ];
    for (final drip in drips) {
      final dx = cx - waxWidth / 2 + waxWidth * drip.dx;
      final h = size.height * drip.len;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx - 2.2, waxTop + 4, 4.4, h),
          const Radius.circular(2.2),
        ),
        dripPaint,
      );
    }
  }

  Path _flamePath(Offset base, double h, double w) {
    return Path()
      ..moveTo(base.dx, base.dy - h)
      ..quadraticBezierTo(base.dx + w, base.dy - h * 0.35, base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx - w,
        base.dy - h * 0.35,
        base.dx,
        base.dy - h,
      );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.lit != lit ||
      oldDelegate.bloom != bloom ||
      oldDelegate.flicker != flicker;
}
