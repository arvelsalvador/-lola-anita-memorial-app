part of 'home_page.dart';

/// The memorial hero: full-bleed background photo with a warm scrim, the
/// arched "In Loving Memory" header, the framed oval portrait, her name,
/// years, tagline, and a divider ornament.
class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key, required this.model, this.onTap});

  final HomeModel model;
  final VoidCallback? onTap;

  static const _photoAsset = 'assets/images/Family DP/Nanay_dp.jpg';
  static const _backgroundAsset =
      'assets/images/Editing images/memorial_header_background_raw.jpg';
  static const _maxContentWidth = 720.0;
  static const _sidePad = 18.0;
  // Top spacing inside the hero (the brand bar above it handles the status
  // bar, so this is just a small breathing gap).
  static const _topPad = 26.0;
  // "In Loving Memory" header above the portrait, styled after the memorial
  // reference graphic: uppercase serif, generous letter-spacing, pale gold,
  // arcing along the top of the portrait's circle. The block is tall because
  // the curved text dips down at its ends.
  static const _memorialBlock = 38.0;
  static const _gapMemorial = 12.0;
  static const _gapPhoto = 16.0;
  static const _nameBlock = 50.0;
  static const _gapName = 6.0;
  static const _yearsBlock = 28.0;
  static const _gapYears = 10.0;
  static const _taglineBlock = 44.0;
  static const _gapTaglineDivider = 14.0;
  static const _dividerBlock = 8.0;
  // Memorial frame PNG (converted from the user's Frame.jpg): a square image
  // with a transparent hole. Measured from the image (1920×1920), the hole is
  // an ellipse that's slightly larger at the bottom (memorial-frame taper):
  // max semi-axes ≈ 0.361 (horizontal) and 0.380 (vertical) of the frame
  // width. The photo is clipped to that ellipse + 3% overscan so it fills the
  // hole with no background gap, and stays well inside the frame's outer edge
  // (~0.41 of the width minimum). The frame PNG is the ONLY framing — the
  // photo underneath is kept plain (no border, no glow), since an extra gold
  // ring there showed through and made the frame look doubled.
  static const _frameAsset = 'assets/images/Editing images/Frame.png';
  static const _frameScale = 1.35;
  static const _holeRxFrac = 0.361; // of frameWidth, measured
  static const _holeRyFrac = 0.380; // of frameWidth, measured (bottom)
  static const _photoOverscan = 1.03;

  // Fallback fonts kick in on platforms (Android/Web) where 'Georgia'
  // isn't registered as an asset font, so text never silently disappears.
  static const _serifFallback = ['Times New Roman', 'serif'];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      color: AppColors.warmDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 380;
          final taglineFont = narrow ? 14.0 : 16.0;
          final nameFont = narrow ? 36.0 : 42.0;

          const statusTop = _topPad;
          const fixed =
              _memorialBlock +
              _gapMemorial +
              _gapPhoto +
              _nameBlock +
              _gapName +
              _yearsBlock +
              _gapYears +
              _taglineBlock +
              _gapTaglineDivider +
              _dividerBlock;
          // The portrait now includes the frame image, which is wider than the
          // photo, so divide by _frameScale to recover the photo circle size.
          final circleSize =
              ((constraints.maxHeight - statusTop - fixed) / _frameScale).clamp(
                64.0,
                150.0,
              );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background image. Decoded at screen width so the
              // header background never holds a full camera bitmap.
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                // Height-axis budget: the background is landscape
                // (2560x1440) behind a portrait phone screen, so height
                // is the cover-limiting axis.
                cacheHeight: ImageDecode.height(
                  MediaQuery.sizeOf(context).height,
                  context,
                ),
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              // Warm dark scrim over the image so the cream text and gold
              // frame stay readable; darker toward the bottom where the name
              // and tagline sit.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Alpha bytes preserved exactly (0x4D / 0x8C / 0xE6).
                    colors: [
                      AppColors.heroScrim.withValues(
                        alpha: 77 / 255,
                      ), // ~30% at top
                      AppColors.warmDark.withValues(
                        alpha: 140 / 255,
                      ), // ~55% mid
                      AppColors.heroScrim.withValues(
                        alpha: 230 / 255,
                      ), // ~90% bottom
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: (constraints.maxWidth - 2 * _sidePad).clamp(
                        0.0,
                        _maxContentWidth - 2 * _sidePad,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: statusTop),
                          _memorialHeader(lang.t('tribute_in_loving_memory')),
                          const SizedBox(height: _gapMemorial),
                          _portrait(context, lang, circleSize),
                          const SizedBox(height: _gapPhoto),
                          _name(nameFont),
                          const SizedBox(height: _gapName),
                          Semantics(
                            label: lang.t('hero_years_label', {
                              'birth': '${model.birthYear}',
                              'passing': '${model.passingYear}',
                            }),
                            child: Text(
                              '${model.birthYear} • ${model.passingYear}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontFamilyFallback: _serifFallback,
                                fontSize: 18,
                                letterSpacing: 2,
                                color: const Color(
                                  0xFFF0E4C8,
                                ).withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapYears),
                          SizedBox(
                            height: _taglineBlock,
                            child: Text(
                              // Localized tagline — add 'hero_tagline' to each
                              // language map (english/tagalog/bicol) so this
                              // switches along with the EN/TL/BC toggle.
                              lang.t('hero_tagline'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontFamilyFallback: _serifFallback,
                                fontSize: taglineFont,
                                color: AppColors.paleGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapTaglineDivider),
                          // Thin divider line with a centered gold diamond,
                          // flush at the bottom edge of the hero so it sits
                          // exactly on the seam between the dark header and
                          // the cream body, matching the design reference.
                          const OrnamentDivider(lineAlpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _memorialHeader(String text) {
    return _CurvedMemorialHeader(text: text);
  }

  Widget _portrait(BuildContext context, LanguageProvider lang, double size) {
    final frameWidth = size * _frameScale;
    return Semantics(
      label: lang.t('hero_portrait_label', {'name': model.name}),
      image: true,
      child: _Pressable(
        borderRadius: BorderRadius.circular(frameWidth / 2),
        onTap: onTap,
        child: SizedBox(
          width: frameWidth,
          height: frameWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _GlowPulse(size: frameWidth * 1.3),
              _photoOval(context, size),
              // Memorial frame PNG with a transparent hole — the photo shows
              // through it and the frame's own gold ring wraps the photo edge.
              Positioned.fill(
                child: Image.asset(
                  _frameAsset,
                  fit: BoxFit.fill,
                  cacheWidth: ImageDecode.width(frameWidth, context),
                  cacheHeight: ImageDecode.height(frameWidth, context),
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOval(BuildContext context, double size) {
    final frameWidth = size * _frameScale;
    return SizedBox(
      width: frameWidth * 2 * _holeRxFrac * _photoOverscan,
      height: frameWidth * 2 * _holeRyFrac * _photoOverscan,
      child: ClipOval(
        child: Image.asset(
          _photoAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          // Height-axis budget: Nanay_dp is landscape (1000x550) in a
          // near-square oval hole, so height is the cover-limiting axis.
          cacheHeight: ImageDecode.height(
            frameWidth * 2 * _holeRyFrac * _photoOverscan,
            context,
          ),
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.warmMid,
            child: const Icon(Icons.person, size: 70, color: AppColors.cream),
          ),
        ),
      ),
    );
  }

  Widget _name(double fontSize) {
    return Semantics(
      header: true,
      child: SizedBox(
        height: _nameBlock,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            model.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lora',
              fontFamilyFallback: _serifFallback,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.cream,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// "In Loving Memory" header that arcs along the top of a circle, matching
/// the arched memorial reference graphic. Each letter is rotated to follow
/// the curve, and a small gold dot flanks each end of the arch.
class _CurvedMemorialHeader extends StatefulWidget {
  const _CurvedMemorialHeader({required this.text});

  final String text;

  // Radius of the arc the text follows. Larger = gentler curve.
  static const _radius = 300.0;
  // Arc-length gap between the text ends and the flanking dots.
  static const _dotGap = 6.0;
  static const _dotRadius = 2.5;

  @override
  State<_CurvedMemorialHeader> createState() => _CurvedMemorialHeaderState();
}

class _CurvedMemorialHeaderState extends State<_CurvedMemorialHeader>
    with SingleTickerProviderStateMixin {
  // One cycle sweeps a soft light across the letters once, then rests
  // before repeating — an occasional shimmer, not a constant glimmer.
  // Stays at 0 (static text) when the OS requests reduced motion.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  @override
  void initState() {
    super.initState();
    if (!animationsDisabled()) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    const style = TextStyle(
      fontFamily: 'Lora',
      fontFamilyFallback: LolaHeroHeader._serifFallback,
      fontSize: 13,
      letterSpacing: 4,
      color: AppColors.paleGold,
      height: 1.1,
    );

    // Lay the whole string out once to get its line height, then lay each
    // character out individually so we can place them along the arc by their
    // own widths (letter-spacing included).
    final whole = TextPainter(
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

    final glyphHeight = whole.height;
    const radius = _CurvedMemorialHeader._radius;
    const dotGap = _CurvedMemorialHeader._dotGap;
    const dotRadius = _CurvedMemorialHeader._dotRadius;
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

