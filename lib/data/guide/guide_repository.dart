import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether this device has already seen the first-run guide.
///
/// The key is versioned so a future content update can deliberately show the
/// guide again by bumping [seenKey]. Every method is failure-tolerant: an
/// unreadable prefs store must never block a visitor, so [hasSeen] reports
/// `false` (show the guide, which is always skippable) and writes are logged
/// and dropped.
class GuideRepository {
  const GuideRepository();

  /// Versioned storage key. Bumped to v2 when the guide became the nav-bar
  /// spotlight, v3 for the two-stop top-bar + nav tour, and v4 when the
  /// Abuloy touch joined as the middle stop.
  static const String seenKey = 'guide_seen_v4';

  /// True when the visitor has already seen (or skipped) the guide.
  Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(seenKey) ?? false;
    } catch (e) {
      debugPrint('GuideRepository: could not read $seenKey ($e)');
      return false;
    }
  }

  /// Marks the guide as seen. Called when the visitor finishes or skips it,
  /// and when the route is popped by the system back gesture.
  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(seenKey, true);
    } catch (e) {
      debugPrint('GuideRepository: could not write $seenKey ($e)');
    }
  }

  /// Clears the flag so the guide can be tested from a clean state.
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(seenKey);
    } catch (e) {
      debugPrint('GuideRepository: could not clear $seenKey ($e)');
    }
  }
}
