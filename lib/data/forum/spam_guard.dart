import 'package:shared_preferences/shared_preferences.dart';

/// Anti-spam rules for the community board (fix #2).
///
/// Three layers, all local-first with no DB migration:
/// 1. Throttle — 1 post / 60s and 1 reply / 20s per device.
/// 2. Blocklist — whole-word profanity + spam snippets, checked before send.
/// 3. Auto-hide — targets with >= [hideThreshold] reports are filtered out.
class SpamGuard {
  static const postCooldown = Duration(seconds: 60);
  static const replyCooldown = Duration(seconds: 20);

  /// Reports from distinct devices that hide a post/reply.
  static const hideThreshold = 3;

  static const _lastPostKey = 'forum_last_post_at_ms';
  static const _lastReplyKey = 'forum_last_reply_at_ms';
  static const _hiddenIdsKey = 'forum_hidden_ids_v1';

  /// Whole-word matches (case-insensitive). Kept short to avoid false
  /// positives — checked with word boundaries, so "analala" never matches.
  static const List<String> blockedWords = [
    'putangina',
    'putang',
    'tangina',
    'tarantado',
    'gago',
    'ulol',
    'bobo',
    'tanga',
    'leche',
    'pakshet',
    'peste',
    'hayop',
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'bastard',
    'casino',
    'crypto',
    'investment',
    'promo',
    'claim',
  ];

  /// Substring matches for links and money spam (no boundaries needed).
  static const List<String> blockedSnippets = [
    'http://',
    'https://',
    'www.',
    '.com',
    'gcash',
    'click here',
    'free load',
  ];

  static bool containsBlockedWords(String text) {
    final lower = text.toLowerCase();
    for (final snippet in blockedSnippets) {
      if (lower.contains(snippet)) return true;
    }
    for (final word in blockedWords) {
      if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(lower)) {
        return true;
      }
    }
    return false;
  }

  static Future<int> secondsUntilNextPost([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    return _remaining(prefs, _lastPostKey, postCooldown, now);
  }

  static Future<int> secondsUntilNextReply([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    return _remaining(prefs, _lastReplyKey, replyCooldown, now);
  }

  static Future<void> recordPost([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastPostKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  static Future<void> recordReply([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastReplyKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  static int _remaining(
    SharedPreferences prefs,
    String key,
    Duration cooldown,
    DateTime? now,
  ) {
    final last = prefs.getInt(key);
    if (last == null) return 0;
    final elapsed =
        (now ?? DateTime.now()).millisecondsSinceEpoch - last;
    final remaining =
        cooldown.inMilliseconds - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / 1000).ceil();
  }

  static Future<Set<String>> loadHiddenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_hiddenIdsKey);
      if (raw == null) return {};
      return raw.toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveHiddenIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_hiddenIdsKey, ids.toList());
    } catch (_) {}
  }
}
