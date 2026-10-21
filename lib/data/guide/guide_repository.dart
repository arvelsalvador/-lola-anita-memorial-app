import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether this device has already seen a guide.
///
/// The key is versioned so a future content update can deliberately show a
/// guide again by bumping the relevant key. Every method is failure-tolerant:
/// an unreadable prefs store must never block a visitor, so [hasSeen] reports
/// `false` (show the guide, which is always skippable) and writes are logged
/// and dropped.
///
/// Three scopes exist today:
///   * the homepage tour (top bar, Abuloy, bottom nav),
///   * the Gallery tour (search, filters, featured slideshow), and
///   * the Family tour (a single "tap a member" hint).
/// They are deliberately independent: a visitor who finished the home tour
/// still gets the Gallery tip the first time they open that tab, and the
/// Family tip the first time they open the Family tab.
class GuideRepository {
  /// Storage key for the homepage tour (top bar, Abuloy, bottom nav).
  ///
  /// Bumped to v2 when the guide became the nav-bar spotlight, v3 for the
  /// two-stop top-bar + nav tour, and v4 when the Abuloy touch joined as the
  /// middle stop.
  static const String seenKey = 'guide_seen_v4';

  /// Storage key for the Gallery tour.
  ///
  /// Bumped to v2 when the third stop — the playable featured slideshow —
  /// landed, so visitors who saw the old two-stop tip get the finished tour
  /// once.
  static const String gallerySeenKey = 'gallery_guide_seen_v2';

  /// Storage key for the Family tour (the single "tap a member" hint).
  ///
  /// Bumped to v2 when the old three-section tour was replaced by this one
  /// tip, so visitors who dismissed the old tour still see the new hint once.
  static const String familySeenKey = 'family_guide_seen_v2';

  /// Storage key for the Words (Mga Salita) tour (the single filter-pills hint).
  static const String wordsSeenKey = 'words_guide_seen_v1';

  /// Storage key for the Condolences (Pakikiramay) tour.
  static const String condolencesSeenKey = 'condolences_guide_seen_v1';

  /// Which persisted flag this instance reads and writes.
  final String storageKey;

  const GuideRepository() : storageKey = seenKey;

  const GuideRepository.gallery() : storageKey = gallerySeenKey;

  const GuideRepository.family() : storageKey = familySeenKey;

  const GuideRepository.words() : storageKey = wordsSeenKey;

  const GuideRepository.condolences() : storageKey = condolencesSeenKey;

  /// True when the visitor has already seen (or skipped) this guide.
  Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(storageKey) ?? false;
    } catch (e) {
      debugPrint('GuideRepository: could not read $storageKey ($e)');
      return false;
    }
  }

  /// Marks the guide as seen. Called when the visitor finishes or skips it,
  /// and when the route is popped by the system back gesture.
  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, true);
    } catch (e) {
      debugPrint('GuideRepository: could not write $storageKey ($e)');
    }
  }

  /// Clears the flag so the guide can be tested from a clean state.
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (e) {
      debugPrint('GuideRepository: could not clear $storageKey ($e)');
    }
  }
}
