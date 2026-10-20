part of 'home_page.dart';

/// The memorial hero: full-bleed background photo with a warm scrim, the
/// arched "In Loving Memory" header, the framed oval portrait, her name,
/// years, tagline, and a divider ornament.
class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key, required this.model, this.onTap});

  final HomeModel model;
  final VoidCallback? onTap;

  static const _backgroundAsset =
      'assets/images/editing_images/memorial_header_background_raw.jpg';
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
          // The width the content column is allowed to take; the portrait
          // must fit inside it or the FittedBox would shrink the whole hero.
          final contentWidth = (constraints.maxWidth - 2 * _sidePad).clamp(
            0.0,
            _maxContentWidth - 2 * _sidePad,
          );
          // The border art is square and wider than the framed photo
          // opening, so the portrait is capped by whichever budget runs out
          // first: the height left after the text blocks, or the width.
          final byHeight =
              (constraints.maxHeight - statusTop - fixed) /
              FramedMemorialPortrait.frameHeightScale;
          final byWidth = contentWidth / FramedMemorialPortrait.frameScale;
          final circleSize = (byHeight < byWidth ? byHeight : byWidth).clamp(
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
                      width: contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: statusTop),
                          _memorialHeader(lang.t('tribute_in_loving_memory')),
                          const SizedBox(height: _gapMemorial),
                          Semantics(
                            label: lang.t('hero_portrait_label', {
                              'name': model.name,
                            }),
                            image: true,
                            child: _Pressable(
                              borderRadius: BorderRadius.circular(
                                circleSize *
                                    FramedMemorialPortrait.frameHeightScale /
                                    2,
                              ),
                              onTap: onTap,
                              child: FramedMemorialPortrait(size: circleSize),
                            ),
                          ),
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
                                fontFamily: 'Inter',
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
                                fontFamily: 'Inter',
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
    return CurvedMemorialHeader(text: text);
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
              fontFamily: 'Inter',
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
