import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only audit trail for the family admin page.
///
/// Per-device, offline-friendly, no Supabase table needed.
/// Stores newest-first list of "time | action | detail".
class AdminAuditLog {
  static const String _key = 'admin_audit_log_v1';
  static const int _maxEntries = 100;

  const AdminAuditLog();

  static Future<void> log(String action, String detail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final List<dynamic> list =
          raw == null || raw.isEmpty ? [] : jsonDecode(raw) as List<dynamic>;
      final entry = {
        'at': DateTime.now().toIso8601String(),
        'action': action.trim(),
        'detail': detail.trim().length > 140
            ? detail.trim().substring(0, 140)
            : detail.trim(),
      };
      final updated = [entry, ...list].take(_maxEntries).toList();
      await prefs.setString(_key, jsonEncode(updated));
    } catch (_) {
      // Audit must never break admin actions.
    }
  }

  static Future<List<Map<String, String>>> fetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return {
          'at': '${m['at'] ?? ''}',
          'action': '${m['action'] ?? ''}',
          'detail': '${m['detail'] ?? ''}',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Builds a simple CSV for visitors / private messages.
  /// Caller copies it to clipboard / shares it.
  static String toCsv(List<List<String>> rows) {
    String cell(String v) {
      final c = v.replaceAll('"', '""').replaceAll('\n', ' ');
      return '"$c"';
    }

    return rows.map((r) => r.map(cell).join(',')).join('\n');
  }
}
