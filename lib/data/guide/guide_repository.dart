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
/// Two scopes exist today:
///   * the homepage tour (top bar, Abuloy, bottom nav), and
///   * the Gallery search-bar tip.
/// They are deliberately independent: a visitor who finished the home tour
/// still gets the Gallery tip the first time they open that tab.
class GuideRepository {
  /// Storage key for the homepage tour (top bar, Abuloy, bottom nav).
  ///
  /// Bumped to v2 when the guide became the nav-bar spotlight, v3 for the
  /// two-stop top-bar + nav tour, and v4 when the Abuloy touch joined as the
  /// middle stop.
  static const String seenKey = 'guide_seen_v4';

  /// Storage key for the Gallery search-bar tour.
  static const String gallerySeenKey = 'gallery_guide_seen_v1';

  /// Which persisted flag this instance reads and writes.
  final String storageKey;

  const GuideRepository() : storageKey = seenKey;

  const GuideRepository.gallery() : storageKey = gallerySeenKey;

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
