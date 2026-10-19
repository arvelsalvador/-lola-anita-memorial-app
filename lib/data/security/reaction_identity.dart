import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Anonymous per-device owner id for Pakikiramay likes.
///
/// The board has no login, so each phone generates one random id (stored
/// on-device) and stamps its Like rows with it. Unlike then deletes only
/// the row carrying this phone's id — it can never eat another
/// visitor's Like. No personal data, never leaves the device except as
/// an opaque tag on the reaction row.
class ReactionIdentity {
  static const String _key = 'memorial_device_id_v1';
  static String? _cached;

  static Future<String> deviceId() async {
    final hit = _cached;
    if (hit != null && hit.isNotEmpty) return hit;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key) ?? '';
    if (id.isEmpty) {
      final r = Random.secure();
      id = 'dev-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
          '-${r.nextInt(1 << 32).toRadixString(36)}';
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }

  /// Test-only reset of the in-memory cache.
  static void debugResetCache() => _cached = null;
}
