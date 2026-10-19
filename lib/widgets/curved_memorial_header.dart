import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/motion.dart';

/// "In Loving Memory" header that arcs along the top of a circle, matching
/// the arched memorial reference graphic. Each letter is rotated to follow
/// the curve, and a small gold dot flanks each end of the arch.
///
/// One cycle sweeps a soft light across the letters, then rests before
/// repeating — an occasional shimmer, not a constant glimmer. Stays static
/// when the OS requests reduced motion. Shared by the home hero and the
/// splash so both open with the same memorial voice.
class CurvedMemorialHeader extends StatefulWidget {
  const CurvedMemorialHeader({super.key, required this.text});

  final String text;

  // Radius of the arc the text follows. Larger = gentler curve.
  static const _radius = 300.0;
  // Arc-length gap between the text ends and the flanking dots.
  static const _dotGap = 6.0;
  static const _dotRadius = 2.5;

  @override
  State<CurvedMemorialHeader> createState() => _CurvedMemorialHeaderState();
}

class _CurvedMemorialHeaderState extends State<CurvedMemorialHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  // Fallback fonts kick in on platforms (Android/Web) where the serif
  // asset isn't registered, so the text never silently disappears.
  static const _serifFallback = ['Times New Roman', 'serif'];

  @override
  void initState() {
    super.initState();
    if (!animationsDisabled()) _controller.repeat();
  }

  // Text layout here is expensive — one TextPainter per character — and
  // the shimmer's AnimatedBuilder below rebuilds this widget on every
  // animation frame, while the CustomPainter keeps painting the same
  // painters across frames. The painters are therefore laid out once and
  // cached until [dispose] (they must stay alive as long as they are
  // painted — disposing right after layout would crash the next paint).
  // Rebuilt only when the text or the text scale changes, e.g. on the
  // language toggle or an accessibility font-size change.
  TextPainter? _whole;
  List<TextPainter>? _chars;
  double _totalWidth = 0;
  double _glyphHeight = 0;
  String? _cachedText;
  TextScaler? _cachedScaler;

  void _layoutIfNeeded() {
    final textScaler = MediaQuery.textScalerOf(context);
    if (_chars != null &&
        _cachedText == widget.text &&
        _cachedScaler == textScaler) {
      return;
    }
    // Drop the previous layout's native resources before rebuilding.
    _whole?.dispose();
    if (_chars != null) {
      for (final tp in _chars!) {
        tp.dispose();
      }
    }

    const style = TextStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: _serifFallback,
      fontSize: 13,
      letterSpacing: 4,
      color: AppColors.paleGold,
      height: 1.1,
    );

    // Lay the whole string out once to get its line height, then lay each
    // character out individually so we can place them along the arc by
    // their own widths (letter-spacing included).
    _whole = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final chars = <TextPainter>[];
    var totalWidth = 0.0;
    for (final rune in widget.text.runes) {
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(rune), style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      chars.add(tp);
      totalWidth += tp.width;
    }

    _chars = chars;
    _cachedText = widget.text;
    _cachedScaler = textScaler;
    _totalWidth = totalWidth;
    _glyphHeight = _whole!.height;
  }

  @override
  void dispose() {
    _controller.dispose();
    _whole?.dispose();
    _whole = null;
    if (_chars != null) {
      for (final tp in _chars!) {
        tp.dispose();
      }
      _chars = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lay out (or re-lay out after a text/scale change) once per change;
    // the shimmer below only repaints with the cached painters.
    _layoutIfNeeded();
    final chars = _chars!;
    final totalWidth = _totalWidth;

    final glyphHeight = _glyphHeight;
    const radius = CurvedMemorialHeader._radius;
    const dotGap = CurvedMemorialHeader._dotGap;
    const dotRadius = CurvedMemorialHeader._dotRadius;
    // The text spans an arc of totalWidth / radius radians; the dots sit
    // just past the text's ends on the same circle.
    final dotAngle = totalWidth / radius / 2 + dotGap / radius;
    final drop = radius * (1 - math.cos(dotAngle));
    final width = 2 * (radius * math.sin(dotAngle) + dotRadius);
    final height = drop + glyphHeight + dotRadius + 2;

    return Semantics(
      label: widget.text,
      header: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(width, height),
            painter: _CurvedTextPainter(
              chars: chars,
              totalWidth: totalWidth,
              glyphHeight: glyphHeight,
              radius: radius,
              dotAngle: dotAngle,
              dotRadius: dotRadius,
              color: AppColors.paleGold,
              shimmerPhase: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  _CurvedTextPainter({
    required this.chars,
    required this.totalWidth,
    required this.glyphHeight,
    required this.radius,
    required this.dotAngle,
    required this.dotRadius,
    required this.color,
    required this.shimmerPhase,
  });

  final List<TextPainter> chars;
  final double totalWidth;
  final double glyphHeight;
  final double radius;
  final double dotAngle;
  final double dotRadius;
  final Color color;

  /// 0..1, looping continuously. Only the first [_sweepWindow] of each
  /// cycle actually sweeps a light across the text; the rest of the cycle
  /// is a quiet rest before the next pass.
  final double shimmerPhase;

  static const _sweepWindow = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Arc center sits below the text so the letters ride the circle's top.
    final cy = radius + glyphHeight / 2;

    // Gold dots at the two ends of the arch.
    final dotPaint = Paint()..color = color.withValues(alpha: 0.7);
    for (final sign in const [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(
          cx + radius * math.sin(sign * dotAngle),
          cy - radius * math.cos(dotAngle),
        ),
        dotRadius,
        dotPaint,
      );
    }

    // Soft highlight traveling along the arc during the sweep window,
    // sitting behind the letters like a light briefly catching the gold.
    if (shimmerPhase <= _sweepWindow && totalWidth > 0) {
      final sweepT = Curves.easeInOut.transform(shimmerPhase / _sweepWindow);
      final highlightPos = -0.15 + sweepT * 1.3; // travels with slight overrun
      if (highlightPos >= -0.05 && highlightPos <= 1.05) {
        final angle = (highlightPos - 0.5) * (totalWidth / radius);
        final hx = cx + radius * math.sin(angle);
        final hy = cy - radius * math.cos(angle);
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(hx, hy), radius: 16));
        canvas.drawCircle(Offset(hx, hy), 16, glowPaint);
      }
    }

    // Letters laid along the arc, each rotated to follow the curve.
    var offset = -totalWidth / 2;
    for (final tp in chars) {
      final w = tp.width;
      final angle = (offset + w / 2) / radius;
      final x = cx + radius * math.sin(angle);
      final y = cy - radius * math.cos(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      tp.paint(canvas, Offset(-w / 2, -tp.height / 2));
      canvas.restore();
      offset += w;
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter oldDelegate) {
    return oldDelegate.shimmerPhase != shimmerPhase ||
        oldDelegate.chars.length != chars.length ||
        oldDelegate.totalWidth != totalWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dotAngle != dotAngle;
  }
}
