import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

class LolaHeroHeader extends StatelessWidget {
  final String name, initial, years, tagline;
  const LolaHeroHeader({
    super.key,
    required this.name,
    required this.initial,
    required this.years,
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Layer 1: dark gradient "sky" — fills whatever height the
        // content Column below ends up needing.
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.warmDark, AppColors.warmDeep],
              ),
            ),
          ),
        ),
        // Layer 2: faint gold botanical line-art on the dark portion.
        Positioned.fill(child: CustomPaint(painter: _BotanicalPainter())),
        // Layer 3: curved cream "hill" — starts around the bottom of the
        // portrait and covers everything below (name/years/tagline).
        Positioned.fill(
          child: ClipPath(
            clipper: _ArchClipper(),
            child: Container(color: AppColors.cream),
          ),
        ),
        // Foreground content — this Column's intrinsic height is what
        // sizes the whole Stack.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const Align(alignment: Alignment.centerLeft, child: _BrandMark()),
                  const SizedBox(height: 18),
                  _PortraitRing(initial: initial),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serifDisplay.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(years, style: AppTextStyles.goldYears),
                  const SizedBox(height: 10),
                  Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: AppColors.muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "nita" wordmark, top-left, in light text since it sits on the dark
/// portion of the header.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_florist,
          size: 16,
          color: AppColors.gold.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        const Text(
          'nita',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 16,
            color: Color(0xFFFAF0E6),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _PortraitRing extends StatelessWidget {
  final String initial;
  const _PortraitRing({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Tight, bright halo hugging the ring edge — layered shadows
        // instead of one big soft blob, so the light reads as coming
        // from the ring itself rather than a glow floating behind it.
        Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFDF6E8).withValues(alpha: 0.9),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 70,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        _PortraitCircle(initial: initial),
      ],
    );
  }
}

class _PortraitCircle extends StatelessWidget {
  final String initial;
  const _PortraitCircle({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFC4956A), Color(0xFF7A4E3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/gallery/Nanay_dp.jpg',
            fit: BoxFit.cover,
            width: 132,
            height: 132,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 52,
                  color: Color(0xFFFAF0E6),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Defines the cream "hill" shape: higher (more cream) at horizontal
/// center where the portrait sits, dipping down toward the edges so the
/// dark background with botanical linework peeks through at the sides —
/// matching the reference design's curved transition.
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final edgeY = size.height * 0.40;
    final peakY = size.height * 0.26;

    path.moveTo(0, edgeY);
    path.quadraticBezierTo(size.width * 0.5, peakY, size.width, edgeY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Faint hand-drawn botanical line-art approximation for the dark portion
/// of the header. Pure Canvas, no new asset/package required — swap for a
/// real SVG if you have exact reference artwork.
class _BotanicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    void branch(Offset origin, bool flip) {
      final dx = flip ? -1.0 : 1.0;
      final path = Path()..moveTo(origin.dx, origin.dy);
      path.quadraticBezierTo(
        origin.dx + dx * 26,
        origin.dy - 36,
        origin.dx + dx * 8,
        origin.dy - 78,
      );
      canvas.drawPath(path, paint);

      for (final t in [0.35, 0.6, 0.85]) {
        final leafCenter = Offset(origin.dx + dx * 18 * t, origin.dy - 78 * t);
        final leaf = Path()
          ..addOval(Rect.fromCenter(center: leafCenter, width: 12, height: 7));
        canvas.drawPath(leaf, paint);
      }
    }

    branch(Offset(size.width * 0.08, size.height * 0.34), false);
    branch(Offset(size.width * 0.92, size.height * 0.34), true);
  }

  @override
  bool shouldRepaint(covariant _BotanicalPainter oldDelegate) => false;
}
