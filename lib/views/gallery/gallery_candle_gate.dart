part of '../gallery_page.dart';

/// Full-screen solemn moment shown before the Remembrances photos.
///
/// The visitor finds a candle waiting beneath her portrait; tapping anywhere
/// lights the flame, a warm light blooms over the scene, and after a short
/// pause the page fades back so the gallery can reveal the photos. Pops with
/// `true` once lit.
class CandleGate extends StatefulWidget {
  final int photoCount;

  const CandleGate({super.key, required this.photoCount});

  @override
  State<CandleGate> createState() => _CandleGateState();
}

class _CandleGateState extends State<CandleGate> with TickerProviderStateMixin {
  static const _portraitAsset = AppAssets.nanayPortrait;

  // Phase offsets so the flame, the portrait's "breathing," and the hand's
  // bob don't all move in perfect lockstep off the same _flicker value.
  // Without these, everything pulses together and reads as mechanical
  // instead of alive.
  static const double _portraitPhaseOffset = 0.37;
  static const double _handPhaseOffset = 0.71;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  // The pointing hand and its "Please tap" text drift on a slower rhythm
  // than the flame, so the invitation feels calm instead of jittery.
  late final AnimationController _handBob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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

  bool _lit = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _entrance.dispose();
    _flicker.dispose();
    _handBob.dispose();
    _bloom.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _lightCandle() {
    if (_lit) return;
    HapticFeedback.lightImpact(); // gentle tactile confirmation the candle caught
    setState(() => _lit = true);
    _bloom.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: Semantics(
        button: true,
        label: lang.t('remembrance_gate_label'),
        hint: lang.t('remembrance_gate_subtitle'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _lightCandle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.35),
                    radius: 1.0,
                    colors: [
                      AppColors.darkAsh,
                      AppColors.darkEmber,
                      AppColors.darkSoot,
                    ],
                  ),
                ),
              ),
              // Warm light that blooms over the whole scene once lit.
              AnimatedBuilder(
                animation: _bloomCurve,
                builder: (context, _) => IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.12),
                        radius: 1.05,
                        colors: [
                          const Color(
                            0xFFFFC96A,
                          ).withValues(alpha: 0.4 * _bloomCurve.value),
                          const Color(
                            0xFFFFC96A,
                          ).withValues(alpha: 0.12 * _bloomCurve.value),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.0,
                        end: 0.4,
                        offset: const Offset(0, -6),
                        child: _gateLabel(lang),
                      ),
                      const SizedBox(height: 18),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.15,
                        end: 0.5,
                        child: _PortraitMedallion(
                          asset: _portraitAsset,
                          lit: _lit,
                          flicker: _flicker,
                          bloom: _bloomCurve,
                          phaseOffset: _portraitPhaseOffset,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.3,
                        end: 0.62,
                        offset: const Offset(0, 10),
                        child: Text(
                          lang.t('remembrance_gate_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.45,
                        end: 0.75,
                        offset: const Offset(0, 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Text(
                            _lit
                                ? lang.t('remembrance_gate_lit')
                                : lang.t('remembrance_gate_subtitle'),
                            key: ValueKey(_lit),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _lit
                                  ? AppColors.goldLight
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.2,
                        end: 0.7,
                        offset: const Offset(0, 34),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: 150,
                          height: 188,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              RepaintBoundary(
                                child: SizedBox(
                                  width: 150,
                                  height: 188,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _flicker,
                                      _bloomCurve,
                                    ]),
                                    builder: (context, _) {
                                      // Two overlapping sine waves at different
                                      // speeds instead of one clean wave — this
                                      // is what makes the flame's sway look
                                      // organic instead of metronomic.
                                      final wobble =
                                          math.sin(
                                                _flicker.value * 2 * math.pi,
                                              ) *
                                              0.7 +
                                          math.sin(
                                                _flicker.value * 5 * math.pi +
                                                    1.1,
                                              ) *
                                              0.3;
                                      return CustomPaint(
                                        painter: _CandlePainter(
                                          lit: _lit,
                                          bloom: _bloomCurve.value,
                                          flicker: wobble,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // A pointing hand above the candle, gently
                              // bobbing, invites the tap. It fades away once
                              // the flame is lit.
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _lit
                                    ? const SizedBox.shrink(
                                        key: ValueKey('lit'),
                                      )
                                    : SizedBox(
                                        key: const ValueKey('unlit'),
                                        width: 150,
                                        height: 188,
                                        child: AnimatedBuilder(
                                          animation: _handBob,
                                          builder: (context, _) {
                                            final bob = math.sin(
                                              (_handBob.value +
                                                      _handPhaseOffset) *
                                                  2 *
                                                  math.pi,
                                            );
                                            final pulse =
                                                0.6 + 0.4 * (0.5 + 0.5 * bob);
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Transform.translate(
                                                  // Upper-right, farther from
                                                  // the candle, finger aimed
                                                  // down-left toward the wick.
                                                  offset: Offset(
                                                    40,
                                                    -34 + bob * 4,
                                                  ),
                                                  child: Transform.rotate(
                                                    angle: -2.4,
                                                    child: const Icon(
                                                      Icons
                                                          .pan_tool_alt_rounded,
                                                      size: 30,
                                                      color:
                                                          AppColors.goldLight,
                                                    ),
                                                  ),
                                                ),
                                                // Gentle pulsing plea right
                                                // beside the hand.
                                                Transform.translate(
                                                  offset: Offset(
                                                    48,
                                                    -56 + bob * 2,
                                                  ),
                                                  child: Opacity(
                                                    opacity: pulse,
                                                    child: Text(
                                                      lang.t(
                                                        'remembrance_gate_please_tap',
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'PlayfairDisplay',
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.goldLight,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.6,
                        end: 0.9,
                        offset: const Offset(0, 8),
                        child: Column(
                          children: [
                            Text(
                              '${widget.photoCount} ${lang.t('gallery_photos')}'
                              '${lang.t('remembrance_gate_held')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.4,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _lit
                                  ? lang.t('remembrance_gate_waiting')
                                  : lang.t('remembrance_gate_tap_hint'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                                color: Colors.white30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: FloatingCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateLabel(LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 1.5708,
          child: const Icon(Icons.eco_rounded, size: 13, color: AppColors.gold),
        ),
        const SizedBox(width: 10),
        Text(
          lang.t('remembrance_gate_label').toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 1.5708,
          child: const Icon(Icons.eco_rounded, size: 13, color: AppColors.gold),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

/// Gold-ringed oval portrait of Nanay. A soft halo gathers behind her once
/// the candle is lit.
class _PortraitMedallion extends StatelessWidget {
  final String asset;
  final bool lit;
  final Animation<double> flicker;
  final Animation<double> bloom;
  final double phaseOffset;

  const _PortraitMedallion({
    required this.asset,
    required this.lit,
    required this.flicker,
    required this.bloom,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([flicker, bloom]),
        builder: (context, child) {
          final breathe =
              1 + 0.015 * math.sin((flicker.value + phaseOffset) * 2 * math.pi);
          return Transform.scale(
            scale: breathe,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(
                      alpha: lit ? 0.45 * bloom.value : 0.22,
                    ),
                    AppColors.gold.withValues(
                      alpha: lit ? 0.1 * bloom.value : 0.0,
                    ),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.6),
                ),
                child: ClipOval(child: child!),
              ),
            ),
          );
        },
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: ImageDecode.width(256, context),
          errorBuilder: (c, e, s) => Container(
            color: AppColors.cream,
            child: const Icon(
              Icons.person_outline_rounded,
              size: 26,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
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
