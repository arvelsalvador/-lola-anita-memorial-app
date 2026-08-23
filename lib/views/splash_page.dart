import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
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

  @override
  void initState() {
    super.initState();

    _petalSeeds = _generatePetalSeeds(_petalCount, seed: 42);

    _sequenceCtrl = AnimationController(
      vsync: this,
      duration: _sequenceDuration,
    );

    _petalCtrl = AnimationController(vsync: this, duration: _petalCycleDuration)
      ..repeat();

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

    _sequenceCtrl.forward();
    _autoAdvanceTimer = Timer(_autoAdvanceDelay, _navigate);
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

    return Scaffold(
      backgroundColor: AppColors.warmDark,
      body: Semantics(
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
                  tapHint: lang.t('splash_tap'),
                ),
              ),
            ],
          ),
        ),
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
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  color: Color(0xFFFAF0E6),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
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
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: Color(0xFFD4BFB5),
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
            colors: [Color(0xFFC4956A), Color(0xFF7A4E3A)],
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
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 40,
                    color: Color(0xFFFAF0E6),
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
