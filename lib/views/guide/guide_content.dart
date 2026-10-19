import 'package:flutter/foundation.dart';

/// The five vector poses bundled under `assets/images/Vector/`.
///
/// The guide points at these by enum, never by hard-coded path, so replacing
/// or adding artwork only touches [GuideArtAsset.asset].
enum GuideArt { wave, pointUp, touchPhone, heart, thumbsUp }

extension GuideArtAsset on GuideArt {
  /// Bundled asset path. The files are transparent PNGs, cropped to the
  /// figure and optimised to ~720px tall (originals kept in
  /// `assets/images/Vector/source/`, which is not registered in pubspec).
  String get asset => switch (this) {
    GuideArt.wave => 'assets/images/Vector/wave.png',
    GuideArt.pointUp => 'assets/images/Vector/point up.png',
    GuideArt.touchPhone => 'assets/images/Vector/touch phone.png',
    GuideArt.heart => 'assets/images/Vector/heart.png',
    GuideArt.thumbsUp => 'assets/images/Vector/thumbs up.png',
  };
}

/// Which part of the real app the step lights up.
enum GuideSpotlight { topBar, abuloy, bottomNav }

/// One stop in the first-visit tour.
///
/// Kept as data rather than inline copy so future steps — her story, photos,
/// the candle — can slot into the same spotlight shell without touching
/// [GuidePage]. The order is the order the visitor sees.
@immutable
class GuideStep {
  final GuideArt art;
  final String titleKey;
  final String bodyKey;
  final GuideSpotlight spotlight;

  const GuideStep({
    required this.art,
    required this.titleKey,
    required this.bodyKey,
    required this.spotlight,
  });
}

/// The Abuloy stop: the floating coin above the bottom nav.
const GuideStep abuloyGuideStep = GuideStep(
  art: GuideArt.touchPhone,
  titleKey: 'guide_abuloy_title',
  bodyKey: 'guide_abuloy_body',
  spotlight: GuideSpotlight.abuloy,
);

/// The bottom-nav stop, pointing at the Nanay artwork.
const GuideStep navGuideStep = GuideStep(
  art: GuideArt.pointUp,
  titleKey: 'guide_nav_title',
  bodyKey: 'guide_nav_body',
  spotlight: GuideSpotlight.bottomNav,
);

/// Top bar first, then Abuloy, then the bottom nav.
///
/// The top bar comes first because it holds the two things a new visitor is
/// most likely to need: the language switch and Settings. Abuloy follows
/// because it is the one control that stays within reach on every tab, and
/// the nav comes last as the map of the whole app.
const List<GuideStep> guideSteps = [
  GuideStep(
    art: GuideArt.wave,
    titleKey: 'guide_topbar_title',
    bodyKey: 'guide_topbar_body',
    spotlight: GuideSpotlight.topBar,
  ),
  abuloyGuideStep,
  navGuideStep,
];
