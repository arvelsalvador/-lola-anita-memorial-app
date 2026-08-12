import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _photoCtrl;
  late AnimationController _petalCtrl;
  late Animation<double> _photoScale;
  late Animation<double> _photoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _quoteOpacity;
  late Animation<double> _tapOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _photoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _petalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _photoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _photoCtrl, curve: Curves.easeOutBack),
    );
    _photoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _photoCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _tapOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _photoCtrl.forward();
    _fadeCtrl.forward();

    Future.delayed(const Duration(seconds: 7), _autoAdvance);
  }

  void _autoAdvance() {
    if (!_navigated && mounted) _navigate();
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _photoCtrl.dispose();
    _petalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.warmDark,
      body: GestureDetector(
        onTap: _navigate,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _petalCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PetalPainter(_petalCtrl.value),
                  size: Size.infinite,
                );
              },
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _photoCtrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _photoOpacity.value,
                        child: Transform.scale(
                          scale: _photoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: _PortraitPhoto(),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _fadeCtrl,
                    builder: (context, child) {
                      return Opacity(opacity: _textOpacity.value, child: child);
                    },
                    child: Column(
                      children: [
                        Text(
                          lang.t('app_title'),
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
                          'Anita Daiz Lumbao',
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
                    animation: _fadeCtrl,
                    builder: (context, child) {
                      return Opacity(opacity: _quoteOpacity.value, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        lang.t('splash_quote'),
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
                    animation: _fadeCtrl,
                    builder: (context, child) {
                      return Opacity(opacity: _tapOpacity.value, child: child);
                    },
                    child: Column(
                      children: [
                        Text(
                          lang.t('splash_tap'),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gold.withOpacity(0.7),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _PulsingDot(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
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
              'assets/images/gallery/Nanay_dp.png',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text(
                  'L',
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

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _PetalPainter extends CustomPainter {
  final double progress;
  static final math.Random _rand = math.Random(42);

  _PetalPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final seed = _rand.nextDouble();
      final x = seed * size.width;
      final yOffset = ((progress + seed * 3) % 4) / 4;
      final y = yOffset * size.height;

      final opacity = (0.08 + _rand.nextDouble() * 0.12);
      paint.color = AppColors.roseLight.withOpacity(opacity);

      final petalPath = Path();
      final petalSize = 4.0 + _rand.nextDouble() * 4;
      petalPath.moveTo(x, y);
      petalPath.quadraticBezierTo(
        x - petalSize,
        y - petalSize,
        x,
        y - petalSize * 2,
      );
      petalPath.quadraticBezierTo(
        x + petalSize,
        y - petalSize,
        x,
        y,
      );
      canvas.drawPath(petalPath, paint);
    }
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
