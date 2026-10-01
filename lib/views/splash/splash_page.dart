import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/motion.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/splash/visitor_gate_form.dart';
import 'package:nita/widgets/app_brand_bar.dart';
import 'package:nita/widgets/pulsing_dot.dart';

/// Splash screen shown on app launch. Auto-advances to [AppRoutes.home]
/// after [_autoAdvanceDelay], or immediately on tap.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _autoAdvanceDelay = Duration(seconds: 7);
  static const _sequenceDuration = Duration(milliseconds: 2000);
  static const _petalCycleDuration = Duration(seconds: 8);
  static const _petalCount = 12;
  static const _portraitSize = 110.0;

  late final AnimationController _sequenceCtrl;
  late final AnimationController _petalCtrl;

  late final Animation<double> _photoScale;
  late final Animation<double> _photoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _quoteOpacity;
  late final Animation<double> _tapOpacity;

  late final List<_PetalSeed> _petalSeeds;

  Timer? _autoAdvanceTimer;
  bool _navigated = false;

  /// Visitor gate state: required name + address, asked once per device.
  /// Returning visitors (saved locally) skip the form entirely.
  /// Testing switch: when true, debug builds always show the form every
  /// run. Release builds always keep remember-me regardless of this flag.
  static const _alwaysAskInDebugForTesting = true;
  final VisitorRepository _visitorRepo = const VisitorRepository();
  bool _checkingVisitor = true;
  bool _hasVisitor = false;

  @override
  void initState() {
    super.initState();

    _petalSeeds = _generatePetalSeeds(_petalCount, seed: 42);

    _sequenceCtrl = AnimationController(
      vsync: this,
      duration: _sequenceDuration,
    );

    _petalCtrl = AnimationController(
      vsync: this,
      duration: _petalCycleDuration,
    );
    // Reduced motion: static petals instead of the falling loop.
    if (!animationsDisabled()) _petalCtrl.repeat();

    _photoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _photoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );
    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _tapOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Reduced motion: skip the entrance choreography, show final state.
    if (animationsDisabled()) {
      _sequenceCtrl.value = 1.0;
    } else {
      _sequenceCtrl.forward();
    }
    _checkVisitor();
  }

  /// Remember-me: returning devices skip the gate and keep the old
  /// auto-advance; new visitors must complete the form (no auto-enter).
  Future<void> _checkVisitor() async {
    bool hasVisitor = false;
    try {
      hasVisitor = await _visitorRepo
          .hasVisitor()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Local prefs unreadable — treat as new visitor, still enterable
      // via the form. Never blocks.
      hasVisitor = false;
    }
    // Testing: debug builds always ask, release keeps remember-me.
    if (kDebugMode && _alwaysAskInDebugForTesting) {
      hasVisitor = false;
    }
    if (!mounted) return;
    setState(() {
      _checkingVisitor = false;
      _hasVisitor = hasVisitor;
    });
    debugPrint('SplashGate: hasVisitor=$hasVisitor');
    if (hasVisitor) {
      _autoAdvanceTimer = Timer(_autoAdvanceDelay, _navigate);
    }
  }

  /// Debug-only: clears the remembered visitor so the gate can be
  /// re-tested from a clean state. The button is compiled out of
  /// release builds (see the kDebugMode guard at the call site).
  Future<void> _resetVisitorForDebug() async {
    try {
      await _visitorRepo.clearVisitor();
    } catch (_) {
      // Prefs unavailable — nothing stored anyway.
    }
    debugPrint('SplashGate: visitor cleared (debug reset)');
    if (!mounted) return;
    setState(() => _hasVisitor = false);
  }

  void _onGateEntered() {
    if (!mounted) return;
    setState(() => _hasVisitor = true);
    _navigate();
  }

  List<_PetalSeed> _generatePetalSeeds(int count, {required int seed}) {
    final random = math.Random(seed);
    return List.generate(
      count,
      (_) => _PetalSeed(
        x: random.nextDouble(),
        phase: random.nextDouble(),
        opacity: 0.08 + random.nextDouble() * 0.12,
        size: 4.0 + random.nextDouble() * 4,
      ),
    );
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    // Gate: new visitors cannot proceed until the form is submitted.
    // _onGateEntered flips _hasVisitor then calls here.
    if (_checkingVisitor || !_hasVisitor) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _sequenceCtrl.dispose();
    _petalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final showGate = !_checkingVisitor && !_hasVisitor;

    return Scaffold(
      backgroundColor: AppColors.warmDark,
      body: Column(
        children: [
          // Splash header: brand + language only. No settings gear and no
          // visitor greeting here — greeting lives on the homepage header.
          const AppBrandBar(),
          Expanded(
            child: Semantics(
              label: lang.t('app_title'),
              button: true,
              hint: lang.t('splash_tap'),
              child: GestureDetector(
                onTap: _navigate,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _petalCtrl,
                          builder: (context, _) => CustomPaint(
                            painter: _PetalPainter(
                              progress: _petalCtrl.value,
                              seeds: _petalSeeds,
                              color: AppColors.roseLight,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: _SplashContent(
                        sequenceCtrl: _sequenceCtrl,
                        photoScale: _photoScale,
                        photoOpacity: _photoOpacity,
                        textOpacity: _textOpacity,
                        quoteOpacity: _quoteOpacity,
                        tapOpacity: _tapOpacity,
                        portraitSize: _portraitSize,
                        appTitle: lang.t('app_title'),
                        subtitle: lang.t('splash_subtitle'),
                        quote: lang.t('splash_quote'),
                        // While the gate is up, tapping does nothing —
                        // the form is the only way in.
                        tapHint: showGate ? '' : lang.t('splash_tap'),
                      ),
                    ),
                    if (showGate)
                      Positioned.fill(
                        child: Container(
                          color: AppColors.warmDark.withValues(alpha: 0.55),
                          child: SafeArea(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      VisitorGateForm(
                                        onEntered: _onGateEntered,
                                      ),
                                      // Temporary testing hook: debug builds only,
                                      // stripped from release via kDebugMode.
                                      if (kDebugMode) ...[
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: _resetVisitorForDebug,
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColors.petalBlush,
                                            textStyle: const TextStyle(
                                              fontFamily: 'Lora',
                                              fontSize: 11,
                                            ),
                                          ),
                                          child: const Text(
                                            'Reset visitor (debug)',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.sequenceCtrl,
    required this.photoScale,
    required this.photoOpacity,
    required this.textOpacity,
    required this.quoteOpacity,
    required this.tapOpacity,
    required this.portraitSize,
    required this.appTitle,
    required this.subtitle,
    required this.quote,
    required this.tapHint,
  });

  final AnimationController sequenceCtrl;
  final Animation<double> photoScale;
  final Animation<double> photoOpacity;
  final Animation<double> textOpacity;
  final Animation<double> quoteOpacity;
  final Animation<double> tapOpacity;
  final double portraitSize;
  final String appTitle;
  final String subtitle;
  final String quote;
  final String tapHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) => Opacity(
            opacity: photoOpacity.value,
            child: Transform.scale(scale: photoScale.value, child: child),
          ),
          child: _PortraitPhoto(size: portraitSize),
        ),
        const SizedBox(height: 28),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: textOpacity.value, child: child),
          child: Column(
            children: [
              Text(
                appTitle,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 24,
                  color: AppColors.linen,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: quoteOpacity.value, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 13,
                color: AppColors.petalBlush,
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: tapOpacity.value, child: child),
          child: Column(
            children: [
              Text(
                tapHint,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gold.withValues(alpha: 0.7),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 12),
              const PulsingDot(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortraitPhoto extends StatelessWidget {
  const _PortraitPhoto({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.dawnRose, AppColors.duskBrown],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ClipOval(
            child: Image.asset(
              'assets/images/Family DP/Nanay_dp.jpg',
              width: size - 20,
              height: size - 20,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              // Height-axis budget: Nanay_dp is landscape (1000x550) in
              // a circular slot, so height is the cover-limiting axis.
              cacheHeight: ImageDecode.height(size - 20, context),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 40,
                    color: AppColors.linen,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetalSeed {
  const _PetalSeed({
    required this.x,
    required this.phase,
    required this.opacity,
    required this.size,
  });

  final double x;
  final double phase;
  final double opacity;
  final double size;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.progress,
    required this.seeds,
    required this.color,
  });

  final double progress;
  final List<_PetalSeed> seeds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final seed in seeds) {
      final x = seed.x * size.width;
      final yOffset = ((progress + seed.phase * 3) % 4) / 4;
      final y = yOffset * size.height;

      paint.color = color.withValues(alpha: seed.opacity);

      final petalPath = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x - seed.size, y - seed.size, x, y - seed.size * 2)
        ..quadraticBezierTo(x + seed.size, y - seed.size, x, y);
      canvas.drawPath(petalPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
