import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/app_routes.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/motion.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/splash/entry_page.dart';
import 'package:nita/controllers/home_controller.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/widgets/app_brand_bar.dart';
import 'package:nita/widgets/curved_memorial_header.dart';
import 'package:nita/widgets/framed_memorial_portrait.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/pulsing_diamond.dart';
import 'package:nita/widgets/splash_video_backdrop.dart';

/// Splash screen shown on app launch. Always the first screen: it waits for
/// a tap, then shows the visitor form (name + address) for a new device, or
/// opens [AppRoutes.home] directly for a remembered one. Nothing happens on
/// its own.
///
/// The first screen speaks the memorial's own language: the dark warm
/// ground and brand bar, a muted looping video clip behind everything, the
/// arched "In Loving Memory" header over the framed portrait, her name in
/// Playfair Display, the years in tracked gold, the quote in Playfair
/// italic, and a lone gold diamond as the "touch to enter" hint — all
/// ornament drawn from the design system (glow, hairlines, diamonds), never
/// petals or stars.
///
/// The clip is a convenience, never a dependency: if it can't decode (or
/// the OS asks for reduced motion, in which case it rests on its first
/// frame), the painted night-vigil backdrop shows instead.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _sequenceDuration = Duration(milliseconds: 2000);
  static const _ambienceCycleDuration = Duration(seconds: 12);
  static const _portraitSize = 104.0;

  late final AnimationController _sequenceCtrl;
  late final AnimationController _ambienceCtrl;

  late final Animation<double> _photoScale;
  late final Animation<double> _photoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _quoteOpacity;
  late final Animation<double> _tapOpacity;

  bool _navigated = false;

  /// True once the splash clip's first frame is up; drives the legibility
  /// scrim so the painted fallback keeps its own look before then.
  bool _videoReady = false;


  /// Visitor gate state: required name + address, asked once per device.
  /// Returning visitors (saved locally) skip the form entirely.
  /// Keep the debug experience consistent with release builds: the gate is
  /// only a test aid when explicitly enabled, not a default behavior that
  /// forces new visitors to re-enter every debug run.
  static const _alwaysAskInDebugForTesting = false;
  final VisitorRepository _visitorRepo = const VisitorRepository();
  bool _hasVisitor = false;

  @override
  void initState() {
    super.initState();

    _sequenceCtrl = AnimationController(
      vsync: this,
      duration: _sequenceDuration,
    );

    _ambienceCtrl = AnimationController(
      vsync: this,
      duration: _ambienceCycleDuration,
    );
    // Reduced motion: static ornaments instead of the drifting loop.
    if (!animationsDisabled()) _ambienceCtrl.repeat();

    _photoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _photoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
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
    _tapOpacity = Tween<double>(begin: 0.0, end: 0.85).animate(
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

  /// Remember-me: returning devices go straight to home on tap; new
  /// visitors get the form after the tap. The splash never advances on its
  /// own — it waits for a tap (or the form's submit).
  Future<void> _checkVisitor() async {
    bool hasVisitor = false;
    try {
      hasVisitor = await _visitorRepo.hasVisitor().timeout(
        const Duration(seconds: 5),
      );
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
      _hasVisitor = hasVisitor;
    });
    debugPrint('SplashGate: hasVisitor=$hasVisitor');
    // A tap landed while the check was still running: now that we know
    // which path applies, take it (home for a remembered visitor, form
    // for a new one — the latter appears via [showGate]).
  }


  /// Called by [SplashVideoBackdrop] once the clip's first frame is ready.
  void _onVideoReady() {
    if (!mounted || _videoReady) return;
    setState(() => _videoReady = true);
  }


  /// Splash tap: the visitor's first interaction. Remembered devices enter
  /// straight away; everyone else gets the name/address form. If the local
  /// prefs check is still in flight, the tap is recorded and the check
  /// decides which path to take when it resolves.
  void _onSplashTapped() {
    if (!mounted || _navigated) return;
    _navigated = true;
    final guideController = context.read<GuideController>();
    final hasEntered = guideController.hasEnteredInfo || _hasVisitor;
    final Widget target = hasEntered ? const HomePage() : const EntryPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
          opacity: animation,
          child: target,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sequenceCtrl.dispose();
    _ambienceCtrl.dispose();
    super.dispose();
  }

  /// The drifting-ornament background, shared by the splash and the gate so
  /// the gate rises out of the same night-vigil world.
  Widget _ambience() {
    return Positioned.fill(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ambienceCtrl,
            builder: (context, _) => CustomPaint(
              painter: _NightVigilBackgroundPainter(
                progress: animationsDisabled() ? 0.0 : _ambienceCtrl.value,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    // The form is a second step: it only exists after the splash is tapped
    // (and only once the local remember-me check has resolved). Returning
    // devices go straight to home instead (see _onSplashTapped).
    const grandmother = HomeController.grandmother;

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
              hint: lang.t('splash_tap_continue'),
              child: GestureDetector(
                onTap: _onSplashTapped,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    // Painted night-vigil backdrop — the ground, and the
                    // fallback whenever the clip is unavailable.
                    _ambience(),
                    // Video ground: fades in over the painter once its first
                    // frame is ready.
                    Positioned.fill(
                      child: SplashVideoBackdrop(
                        asset: AppAssets.splashVideo,
                        onReady: _onVideoReady,
                      ),
                    ),
                    // Legibility scrim, faded in with the video so the painted
                    // fallback keeps its own look before then. Keeps her name,
                    // years and quote crisp over the moving clip.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _videoReady ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.heroScrim.withValues(alpha: 0.55),
                                  AppColors.warmDark.withValues(alpha: 0.40),
                                  AppColors.heroScrim.withValues(alpha: 0.66),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _SplashContent(
                                sequenceCtrl: _sequenceCtrl,
                                photoScale: _photoScale,
                                photoOpacity: _photoOpacity,
                                textOpacity: _textOpacity,
                                quoteOpacity: _quoteOpacity,
                                tapOpacity: _tapOpacity,
                                portraitSize: _portraitSize,
                                lovingMemory: lang.t(
                                  'tribute_in_loving_memory',
                                ),
                                name: grandmother.name,
                                years:
                                    '${grandmother.birthYear}  •  ${grandmother.passingYear}',
                                quote: lang.t('splash_quote'),
                                // While the gate is up, tapping does nothing —
                                // the form is the only way in.
                                tapHint: lang.t('splash_tap_continue'),
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
    required this.lovingMemory,
    required this.name,
    required this.years,
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
  final String lovingMemory;
  final String name;
  final String years;
  final String quote;
  final String tapHint;

  // Playfair Display is the display voice; the serif fallback keeps the
  // words visible on platforms without the bundled face.
  static const _serifFallback = ['Times New Roman', 'serif'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arched "In Loving Memory" riding the top of the framed portrait.
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) => Opacity(
            opacity: photoOpacity.value,
            child: Transform.scale(scale: photoScale.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurvedMemorialHeader(text: lovingMemory),
              const SizedBox(height: 12),
              FramedMemorialPortrait(size: portraitSize),
            ],
          ),
        ),
        const SizedBox(height: 26),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: textOpacity.value, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontFamilyFallback: _serifFallback,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream,
                  height: 1.1,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                years,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.goldLight,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const OrnamentDivider(lineLength: 96, lineAlpha: 0.4),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: quoteOpacity.value, child: child),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontFamilyFallback: _serifFallback,
                fontStyle: FontStyle.italic,
                fontSize: 15,
                color: AppColors.petalBlush,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: sequenceCtrl,
          builder: (context, child) =>
              Opacity(opacity: tapOpacity.value, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreathingTapHint(text: tapHint),
              const SizedBox(height: 12),
              const PulsingDiamond(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Night-vigil ambience: a soft gold glow behind the portrait, a few gold
/// diamonds drifting slowly down the screen (the system's ornament, standing
/// in for falling petals), and a quiet ground mist. All motion is a pure
/// function of [progress]; pass 0 for a fully static backdrop.
class _NightVigilBackgroundPainter extends CustomPainter {
  _NightVigilBackgroundPainter({required this.progress});

  final double progress;

  static const _diamondCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final minSide = math.min(size.width, size.height);

    // Soft gold warmth behind the portrait — the candle glow of the vigil.
    final glowCenter = Offset(size.width * 0.5, size.height * 0.34);
    final glowRadius = minSide * 0.62;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.paleGold.withValues(alpha: 0.10),
          AppColors.paleGold.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // Gold diamonds drifting down, deterministic from the index so no seed
    // list is needed. Kept very faint — ornament, not decoration.
    final diamondPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _diamondCount; i++) {
      final x = ((i * 0.61803398875) % 1.0) * size.width;
      final speed = 0.5 + (i % 4) * 0.3;
      final y = ((i * 0.3571 + progress * speed) % 1.0) * size.height;
      final side = 3.0 + (i % 3) * 1.5;
      final alpha = 0.05 + (i % 5) * 0.02;
      diamondPaint.color = AppColors.gold.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        diamondPaint,
      );
      canvas.restore();
    }

    // Soft ground mist along the bottom.
    diamondPaint.color = AppColors.petalBlush.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 1.02),
      minSide * 0.55,
      diamondPaint,
    );
    diamondPaint.color = AppColors.rose.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 1.0),
      minSide * 0.35,
      diamondPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NightVigilBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


/// The "touch to enter" hint, breathing slowly so it reads as an invitation
/// rather than a caption over the moving clip.
///
/// One controller drives three properties together — gold alpha, a soft glow
/// and a slight swell — so the whole hint pulses as a single heartbeat. The
/// cycle is kept close to [PulsingDiamond]'s below it so the two read as one
/// beat rather than two competing rhythms.
///
/// Reduced motion holds the hint at its peak glow: fully legible, still gold,
/// just not moving.
class _BreathingTapHint extends StatefulWidget {
  const _BreathingTapHint({required this.text});

  final String text;

  /// Rest and peak values for the breath. Rest stays well above invisible so
  /// the hint never fully disappears between beats.
  static const _restAlpha = 0.40;
  static const _peakAlpha = 1.0;

  @override
  State<_BreathingTapHint> createState() => _BreathingTapHintState();
}

class _BreathingTapHintState extends State<_BreathingTapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Eased 0..1 breath, shared by alpha, glow and scale.
  late final Animation<double> _breath = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    if (animationsDisabled()) {
      // Static peak: legible gold, no loop.
      _ctrl.value = 1.0;
    } else {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to hint at while the gate form owns the screen.
    if (widget.text.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        final alpha = _BreathingTapHint._restAlpha +
            (_BreathingTapHint._peakAlpha - _BreathingTapHint._restAlpha) * t;
        final glow = 0.15 + 0.30 * t;
        return Transform.scale(
          scale: 1.0 + 0.06 * t,
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.gold.withValues(alpha: alpha),
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
              shadows: [
                Shadow(
                  color: AppColors.gold.withValues(alpha: glow),
                  blurRadius: 5 + 7 * t,
                ),
                Shadow(
                  color: AppColors.paleGold.withValues(alpha: glow * 0.7),
                  blurRadius: 10 + 12 * t,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
