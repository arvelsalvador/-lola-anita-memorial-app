import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which posts and replies were created on this device (fix #4).
///
/// The board has no login, so "mine" = an id in these sets. The sets
/// survive restarts; reinstalls lose ownership (accepted — it also blocks
/// impersonation edits from a fresh install). Temp ids (`msg-…`,
/// `reply-…`) are migrated to real server ids on live echo.
class OwnIds {
  static const _postsKey = 'forum_own_post_ids_v1';
  static const _repliesKey = 'forum_own_reply_ids_v1';

  static Future<Set<String>> loadPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_postsKey)?.toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> loadReplies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_repliesKey)?.toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> addPost(String id) async {
    if (id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_postsKey)?.toSet() ?? {};
      if (ids.add(id)) {
        await prefs.setStringList(_postsKey, ids.toList());
      }
    } catch (_) {}
  }

  static Future<void> addReply(String id) async {
    if (id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_repliesKey)?.toSet() ?? {};
      if (ids.add(id)) {
        await prefs.setStringList(_repliesKey, ids.toList());
      }
    } catch (_) {}
  }

  static Future<void> removePost(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_postsKey)?.toSet() ?? {};
      if (ids.remove(id)) {
        await prefs.setStringList(_postsKey, ids.toList());
      }
    } catch (_) {}
  }

  static Future<void> removeReply(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_repliesKey)?.toSet() ?? {};
      if (ids.remove(id)) {
        await prefs.setStringList(_repliesKey, ids.toList());
      }
    } catch (_) {}
  }

  /// Moves ownership from a temp id to its real server id.
  static Future<void> migratePost(String tempId, String realId) async {
    if (tempId.isEmpty || realId.isEmpty || tempId == realId) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_postsKey)?.toSet() ?? {};
      if (ids.remove(tempId)) {
        ids.add(realId);
        await prefs.setStringList(_postsKey, ids.toList());
      }
    } catch (_) {}
  }

  /// Moves ownership from a temp id to its real server id.
  static Future<void> migrateReply(String tempId, String realId) async {
    if (tempId.isEmpty || realId.isEmpty || tempId == realId) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_repliesKey)?.toSet() ?? {};
      if (ids.remove(tempId)) {
        ids.add(realId);
        await prefs.setStringList(_repliesKey, ids.toList());
      }
    } catch (_) {}
  }
}
