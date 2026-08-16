import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key});

  static const _photoAsset = 'assets/images/gallery/Nanay_dp.jpg';
  static const _maxContentWidth = 720.0;
  static const _sidePad = 18.0;
  static const _gapLogo = 14.0;
  static const _gapPhoto = 16.0;
  static const _nameBlock = 50.0;
  static const _gapName = 6.0;
  static const _yearsBlock = 28.0;
  static const _gapYears = 12.0;
  static const _taglineBlock = 44.0;
  static const _gapTagline = 14.0;
  static const _bottomPad = 34.0;

  static double _quoteCardHeight(double quoteFont) =>
      40 + 20 + 4 + 4 * quoteFont * 1.3 + 10 + 1 + 8 + 20;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      color: AppColors.warmDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 380;
          final quoteFont = narrow ? 17.0 : 21.0;
          final taglineFont = narrow ? 14.0 : 16.0;
          final nameFont = narrow ? 36.0 : 42.0;
          final attributionFont = narrow ? 13.0 : 15.0;

          final statusTop = topPad + 12.0;
          final fixed = _gapLogo +
              _gapPhoto +
              _nameBlock +
              _gapName +
              _yearsBlock +
              _gapYears +
              _taglineBlock +
              _gapTagline +
              _quoteCardHeight(quoteFont) +
              _bottomPad;
          final circleSize =
              (constraints.maxHeight - statusTop - fixed).clamp(110.0, 192.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A100D),
                      AppColors.warmDark,
                      Color(0xFF2F1D18),
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: (constraints.maxWidth - 2 * _sidePad)
                          .clamp(0.0, _maxContentWidth - 2 * _sidePad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: statusTop),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'nita',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.goldLight,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapLogo),
                          _portrait(circleSize),
                          const SizedBox(height: _gapPhoto),
                          _name(nameFont),
                          const SizedBox(height: _gapName),
                          Text(
                            '1940 • 2025',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 18,
                              letterSpacing: 2,
                              color: const Color(0xFFF0E4C8).withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapYears),
                          SizedBox(
                            height: _taglineBlock,
                            child: Text(
                              'Beloved grandmother, keeper of stories',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: taglineFont,
                                fontStyle: FontStyle.italic,
                                color: AppColors.cream.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                          const SizedBox(height: _gapTagline),
                          _quoteCard(quoteFont, attributionFont),
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
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.33),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          _photoAsset,
          fit: BoxFit.cover,
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
    );
  }

  Widget _name(double fontSize) {
    return SizedBox(
      height: _nameBlock,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Anita Daiz Lumbao',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.cream,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _quoteCard(double quoteFont, double attributionFont) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E7DE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '“',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 40,
              color: AppColors.warmDeep,
              height: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ang kusina ay kung saan ang\npagmamahal ay nagiging lasa.\nMagluto gamit ang dalawang kamay\nat bukas na puso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: quoteFont,
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(
            thickness: 1,
            color: AppColors.gold,
            indent: 30,
            endIndent: 30,
          ),
          const SizedBox(height: 8),
          Text(
            '— Nanay Nita, palaging sinasabi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: attributionFont,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}