import 'package:flutter/foundation.dart';

/// The five vector poses bundled under `assets/images/vector/`.
///
/// The guide points at these by enum, never by hard-coded path, so replacing
/// or adding artwork only touches [GuideArtAsset.asset].
enum GuideArt { wave, pointUp, touchPhone, heart, thumbsUp }

extension GuideArtAsset on GuideArt {
  /// Bundled asset path. The files are transparent PNGs, cropped to the
  /// figure and optimised to ~720px tall (originals kept in
  /// `assets/images/vector/source/`, which is not registered in pubspec).
  String get asset => switch (this) {
    GuideArt.wave => 'assets/images/vector/wave.png',
    GuideArt.pointUp => 'assets/images/vector/point_up.png',
    GuideArt.touchPhone => 'assets/images/vector/touch_phone.png',
    GuideArt.heart => 'assets/images/vector/heart.png',
    GuideArt.thumbsUp => 'assets/images/vector/thumbs_up.png',
  };
}

/// Which part of the real app the step lights up.
enum GuideSpotlight {
  topBar,
  abuloy,
  bottomNav,
  gallerySearchBar,
  galleryFilterPills,
  galleryFeaturedCard,
  familyMember,
  wordsFilterPills,
  condolencesPrivateMessage,
  condolencesCommunityForum,
  condolencesReplyReact,
}

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

/// The Gallery search-bar stop. The search field narrows the photo grid as
/// the visitor types, so it is the first thing worth learning on that tab.
const GuideStep gallerySearchGuideStep = GuideStep(
  art: GuideArt.touchPhone,
  titleKey: 'gallery_guide_search_title',
  bodyKey: 'gallery_guide_search_body',
  spotlight: GuideSpotlight.gallerySearchBar,
);

/// The Gallery filter-pill stop. The row narrows the grid by category, and
/// the Huling Araw pill is the candle-gated last-day section worth pointing
/// out in the same breath.
const GuideStep galleryFilterPillsGuideStep = GuideStep(
  art: GuideArt.pointUp,
  titleKey: 'gallery_guide_pills_title',
  bodyKey: 'gallery_guide_pills_body',
  spotlight: GuideSpotlight.galleryFilterPills,
);

/// The Gallery featured-memory stop. Tapping the card opens the slideshow,
/// which plays her photos with background music.
const GuideStep galleryFeaturedGuideStep = GuideStep(
  art: GuideArt.heart,
  titleKey: 'gallery_guide_featured_title',
  bodyKey: 'gallery_guide_featured_body',
  spotlight: GuideSpotlight.galleryFeaturedCard,
);

/// The Gallery tour: search, then filters, then the featured slideshow. The
/// order is the order the visitor sees.
const List<GuideStep> galleryGuideSteps = [
  gallerySearchGuideStep,
  galleryFilterPillsGuideStep,
  galleryFeaturedGuideStep,
];

/// The Family tour's only stop: a member card. Tapping any card on the
/// Pamilya page opens that person's detail sheet.
const GuideStep familyMemberGuideStep = GuideStep(
  art: GuideArt.pointUp,
  titleKey: 'family_guide_member_title',
  bodyKey: 'family_guide_member_body',
  spotlight: GuideSpotlight.familyMember,
);

const List<GuideStep> familyGuideSteps = [familyMemberGuideStep];

/// The Words (Mga Salita) tour's only stop: the filter pills row.
const GuideStep wordsFilterPillsGuideStep = GuideStep(
  art: GuideArt.pointUp,
  titleKey: 'words_guide_pills_title',
  bodyKey: 'words_guide_pills_body',
  spotlight: GuideSpotlight.wordsFilterPills,
);

const List<GuideStep> wordsGuideSteps = [wordsFilterPillsGuideStep];

/// The Pakikiramay private-message stop.
const GuideStep condolencesPrivateMessageStep = GuideStep(
  art: GuideArt.heart,
  titleKey: 'condolences_guide_private_title',
  bodyKey: 'condolences_guide_private_body',
  spotlight: GuideSpotlight.condolencesPrivateMessage,
);

/// The Pakikiramay community-forum stop.
const GuideStep condolencesCommunityForumStep = GuideStep(
  art: GuideArt.touchPhone,
  titleKey: 'condolences_guide_forum_title',
  bodyKey: 'condolences_guide_forum_body',
  spotlight: GuideSpotlight.condolencesCommunityForum,
);

/// The Pakikiramay reply & react stop.
const GuideStep condolencesReplyReactStep = GuideStep(
  art: GuideArt.thumbsUp,
  titleKey: 'condolences_guide_react_title',
  bodyKey: 'condolences_guide_react_body',
  spotlight: GuideSpotlight.condolencesReplyReact,
);

/// The Pakikiramay tour: private message, community stories, then reply & react.
const List<GuideStep> condolencesGuideSteps = [
  condolencesPrivateMessageStep,
  condolencesCommunityForumStep,
  condolencesReplyReactStep,
];
