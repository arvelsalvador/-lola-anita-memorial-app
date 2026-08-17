import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key});

  static const _photoAsset = 'assets/images/gallery/Nanay_dp.jpg';
  static const _backgroundAsset =
      'assets/images/gallery/memorial_header_background_raw.jpg';
  static const _maxContentWidth = 720.0;
  static const _sidePad = 18.0;
  // Top spacing inside the hero (the brand bar above it handles the status
  // bar, so this is just a small breathing gap).
  static const _topPad = 16.0;
  static const _gapPhoto = 16.0;
  static const _nameBlock = 50.0;
  static const _gapName = 6.0;
  static const _yearsBlock = 28.0;
  static const _gapYears = 10.0;
  static const _taglineBlock = 44.0;
  static const _bottomPad = 22.0;
  // Memorial frame PNG (converted from the user's Frame.jpg): a square image
  // with a transparent hole. Measured from the image (1920×1920), the hole is
  // an ellipse that's slightly larger at the bottom (memorial-frame taper):
  // max semi-axes ≈ 0.361 (horizontal) and 0.380 (vertical) of the frame
  // width. The photo is clipped to that ellipse + 3% overscan so it fills the
  // hole with no background gap, and stays well inside the frame's outer edge
  // (~0.41 of the width minimum). The frame PNG is the ONLY framing — the
  // photo underneath is kept plain (no border, no glow), since an extra gold
  // ring there showed through and made the frame look doubled.
  static const _frameAsset = 'assets/images/gallery/Frame.png';
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

          final statusTop = _topPad;
          final fixed =
              _gapPhoto +
              _nameBlock +
              _gapName +
              _yearsBlock +
              _gapYears +
              _taglineBlock +
              _bottomPad;
          // The portrait now includes the frame image, which is wider than the
          // photo, so divide by _frameScale to recover the photo circle size.
          final circleSize =
              ((constraints.maxHeight - statusTop - fixed) / _frameScale)
                  .clamp(100.0, 150.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed background image.
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              // Warm dark scrim over the image so the cream text and gold
              // frame stay readable; darker toward the bottom where the name
              // and tagline sit.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x4D1A100D), // ~30% at top
                      Color(0x8C2E1F17), // ~55% mid
                      Color(0xE61A100D), // ~90% bottom
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
                          SizedBox(height: statusTop),
                          _portrait(circleSize),
                          const SizedBox(height: _gapPhoto),
                          _name(nameFont),
                          const SizedBox(height: _gapName),
                          Semantics(
                            label: 'Lived from 1940 to 2025',
                            child: Text(
                              '1940 • 2025',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
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
                                fontFamily: 'Georgia',
                                fontFamilyFallback: _serifFallback,
                                fontSize: taglineFont,
                                fontStyle: FontStyle.italic,
                                color: AppColors.cream.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                          const SizedBox(height: _bottomPad),
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

  Widget _portrait(double size) {
    final frameWidth = size * _frameScale;
    return Semantics(
      label: 'Photo of Anita Daiz Lumbao',
      image: true,
      child: SizedBox(
        width: frameWidth,
        height: frameWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _photoOval(size),
            // Memorial frame PNG with a transparent hole — the photo shows
            // through it and the frame's own gold ring wraps the photo edge.
            Positioned.fill(
              child: Image.asset(
                _frameAsset,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOval(double size) {
    final frameWidth = size * _frameScale;
    return SizedBox(
      width: frameWidth * 2 * _holeRxFrac * _photoOverscan,
      height: frameWidth * 2 * _holeRyFrac * _photoOverscan,
      child: ClipOval(
        child: Image.asset(
          _photoAsset,
          fit: BoxFit.cover,
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
            'Anita Daiz Lumbao',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
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

