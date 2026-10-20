import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/utils/motion.dart';

/// Anita's portrait inside the memorial border art — a 1254×1254 gold wreath
/// whose circular opening is ringed by pearls and flanked by lilies — with a
/// soft breathing gold glow behind it.
///
/// Measured from the border image, the opening is a circle centred at
/// (0.4967, 0.4713) of the art width with radius 0.3494 of the art width
/// (least-squares fit over 30 chords of the opening, max deviation ~2 px).
/// The photo is clipped to that circle + 3% overscan so it fills the opening
/// with no background gap; the band around the opening is artwork ~0.03
/// art-widths thick, so the overscan stays hidden underneath it. The border
/// PNG is the ONLY framing — the photo underneath stays plain (no border, no
/// glow of its own), since an extra gold ring there showed through and made
/// the frame look doubled.
///
/// The art is full-bleed — the flourishes reach within ~2% of its edges — so
/// nothing is cropped ([_artCrop] is 0) and the opening sits exactly where
/// it does in the image.
///
/// The art is square, so the widget is [size] × [frameScale] wide and
/// [size] × [frameHeightScale] tall, and the two budgets are equal.
///
/// Shared by the home hero and the splash so the portrait reads as one
/// identity on both screens.
class FramedMemorialPortrait extends StatelessWidget {
  const FramedMemorialPortrait({
    super.key,
    required this.size,
    this.photoAsset = AppAssets.nanayPortrait,
    this.frameAsset = _frameAsset,
    this.showGlow = true,
  });

  /// Budgeted photo width; the art is [size] × [frameScale] wide.
  final double size;

  final String photoAsset;
  final String frameAsset;

  /// Set false for a still portrait with no glow behind it.
  final bool showGlow;

  static const _frameAsset =
      'assets/images/editing_images/main_border.png';

  /// Border art aspect, height ÷ width (1254 ÷ 1254).
  static const double frameAspect = 1254 / 1254;

  // Opening geometry, all as fractions of the art's width. The opening is a
  // circle, so the semi-axes are equal.
  static const _holeCxFrac = 0.4967;
  static const _holeCyFrac = 0.4713;
  static const _holeRxFrac = 0.3494;
  static const _holeRyFrac = 0.3494;
  static const _photoOverscan = 1.03;

  // The current art is full-bleed: opaque pixels span y 0.004–0.964 of its
  // height and the lilies reach both horizontal edges, so there is no
  // glow-only margin to cut and the art is laid out whole. _artCrop = 0 also
  // keeps the opening centred in the laid-out box.
  static const _artCrop = 0.0;

  /// Laid-out height of the art as a fraction of its width.
  static const _artVisibleAspect = frameAspect - 2 * _artCrop;

  /// Art width per unit of [size] — the opening is 2 × [_holeRxFrac] of it,
  /// so this keeps a photo of [size] exactly filling the opening.
  static const double frameScale = 1 / (2 * _holeRxFrac);

  /// Art height per unit of [size]. Use this to budget vertical space.
  static const double frameHeightScale = frameScale * _artVisibleAspect;

  @override
  Widget build(BuildContext context) {
    final frameWidth = size * frameScale;
    final frameHeight = frameWidth * _artVisibleAspect;
    final artHeight = frameWidth * frameAspect;
    // Vertical centre of the opening once the top margin is cropped away.
    final holeCenterY = (_holeCyFrac - _artCrop) * frameWidth;

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      // The glow is wider than the content band and is meant to bleed past
      // the border, so only the art itself is clipped.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showGlow) _glow(frameWidth, holeCenterY),
          _photoOval(context, frameWidth, holeCenterY),
          // Border art with a transparent opening — the photo shows through
          // it and the art's own ring wraps the photo edge. The art is the
          // same size as this box (square, uncropped), so the OverflowBox
          // simply centres it.
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                minHeight: artHeight,
                maxHeight: artHeight,
                child: Image.asset(
                  frameAsset,
                  fit: BoxFit.fill,
                  cacheWidth: ImageDecode.width(frameWidth, context),
                  cacheHeight: ImageDecode.height(artHeight, context),
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Halo centred on the opening rather than on the content band, since the
  /// flourishes hang well below the oval.
  Widget _glow(double frameWidth, double holeCenterY) {
    final glowSize = frameWidth * 2 * _holeRxFrac * 2.4;
    return Positioned(
      left: _holeCxFrac * frameWidth - glowSize / 2,
      top: holeCenterY - glowSize / 2,
      child: _GlowPulse(size: glowSize),
    );
  }

  Widget _photoOval(
    BuildContext context,
    double frameWidth,
    double holeCenterY,
  ) {
    final ovalWidth = frameWidth * 2 * _holeRxFrac * _photoOverscan;
    final ovalHeight = frameWidth * 2 * _holeRyFrac * _photoOverscan;
    return Positioned(
      left: _holeCxFrac * frameWidth - ovalWidth / 2,
      top: holeCenterY - ovalHeight / 2,
      child: SizedBox(
        width: ovalWidth,
        height: ovalHeight,
        child: ClipOval(
          child: Image.asset(
            photoAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            // Width-axis budget: Nanay_dp is portrait (1183×1329) in a
            // near-square oval hole, so width is the cover-limiting axis.
            // Budgeting the height instead decodes ~7% narrower than the oval
            // and stretches her face, which reads as blur.
            cacheWidth: ImageDecode.width(ovalWidth, context),
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.warmMid,
              child: const Icon(
                Icons.person,
                size: 70,
                color: AppColors.cream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow, quiet warmth behind the portrait frame — a soft radial glow that
/// breathes in and out over several seconds. Meant to feel like a candle's
/// light, not a UI effect; kept subtle on purpose.
class _GlowPulse extends StatefulWidget {
  final double size;
  const _GlowPulse({required this.size});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  // Static mid-glow when the OS requests reduced motion.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (animationsDisabled()) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final peak = AppColors.paleGold.withValues(alpha: 0.10 + 0.16 * t);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Extra stops feather the tail: a two-stop ramp leaves a visible
            // disc edge now that the border is narrower than the halo.
            gradient: RadialGradient(
              colors: [
                peak,
                peak.withValues(alpha: peak.a * 0.55),
                peak.withValues(alpha: peak.a * 0.15),
                peak.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 0.75, 1],
            ),
          ),
        );
      },
    );
  }
}
