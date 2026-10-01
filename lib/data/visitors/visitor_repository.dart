import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/supabase_config.dart';

/// Visitor log for the splash gate: name + full address, required once.
///
/// Local-first: the gate always saves on-device and lets the visitor in.
/// Supabase insert runs in the background with a short timeout and never
/// throws to the UI — a mourning visitor is never blocked by network.
/// The `visitors` table is private (anon INSERT only, no public SELECT).
class VisitorRepository {
  const VisitorRepository();

  static const _kName = 'visitor_name';
  static const _kAddress = 'visitor_address';
  static const _kSavedAt = 'visitor_saved_at';

  /// True when this device already completed the gate once.
  Future<bool> hasVisitor() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kName)?.trim() ?? '';
    final address = prefs.getString(_kAddress)?.trim() ?? '';
    return name.isNotEmpty && address.isNotEmpty;
  }

  Future<String?> localName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  /// First token of a full name for compact greetings ("Arvel Salvador"
  /// -> "Arvel"). Returns '' for null/empty/blank input so callers can
  /// fall back to brand-only UI.
  static String firstName(String? fullName) {
    final clean = (fullName ?? '').trim();
    if (clean.isEmpty) return '';
    return clean.split(RegExp(r'\s+')).first;
  }

  /// Testing/debug helper: wipes the remembered visitor so the splash
  /// gate shows again from a clean state.
  Future<void> clearVisitor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kAddress);
    await prefs.remove(_kSavedAt);
  }

  /// Saves locally (fast, always) then tries Supabase in background.
  /// Returns true when the remote insert succeeded.
  Future<bool> saveVisitor({
    required String name,
    required String address,
    String lang = 'tl',
  }) async {
    final cleanName = name.trim();
    final cleanAddress = address.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, cleanName);
    await prefs.setString(_kAddress, cleanAddress);
    await prefs.setString(_kSavedAt, DateTime.now().toIso8601String());

    if (!SupabaseConfig.isConfigured) return false;
    try {
      final client = Supabase.instance.client;
      await client.from('visitors').insert({
        'name': cleanName,
        'address': cleanAddress,
        'lang': lang,
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      // Offline / RLS / table-missing / Data API disabled: entry already
      // saved locally, remote sync can be retried on next launch.
      // 404 Not Found usually means wrong SUPABASE_URL or the table is
      // not exposed to the Data API — check redacted URL + policies.
      debugPrint(
        'VisitorRepository: remote save to visitors skipped '
        '(${SupabaseConfig.redactedUrl} $e) '
        'hint: real https URL, Data API enabled, anon INSERT policy.',
      );
      return false;
    }
  }

  static const String table = 'visitors';

  /// How many visitors entered the app (rows in [table]).
  /// Returns null when offline/unconfigured/denied (caller shows fallback).
  /// Never throws.
  Future<int?> fetchVisitorCount() async {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from(table)
          .select('id')
          .timeout(const Duration(seconds: 8));
      return (rows as List).length;
    } catch (e) {
      debugPrint(
        'VisitorRepository: visitor count skipped '
        '(${SupabaseConfig.redactedUrl} $e)',
      );
      return null;
    }
  }

  /// Names-only list of who visited, newest first.
  /// Selects `name, created_at` only — addresses and lang stay private
  /// and are never rendered. Returns null when offline/unconfigured/
  /// denied, empty list when online with no rows yet. Never throws.
  Future<List<String>?> fetchVisitorNames({int limit = 50}) async {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from(table)
          .select('name, created_at')
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 8));
      final names = <String>[];
      for (final row in (rows as List)) {
        final raw = (row as Map)['name'];
        final name = (raw is String ? raw : '').trim();
        if (name.isEmpty) continue;
        names.add(name.length > 50 ? name.substring(0, 50) : name);
      }
      return names;
    } catch (e) {
      debugPrint(
        'VisitorRepository: visitor names skipped '
        '(${SupabaseConfig.redactedUrl} $e)',
      );
      return null;
    }
  }

  /// Address rule for the gate: full address, required, 3–200 chars.
  /// Min 3 so short real place names pass (`Daet`, `Labo`, `Naga`).
  /// Returns a translation key, or null when valid.
  static String? validateAddress(String input) {
    final value = input.trim();
    if (value.isEmpty) return 'visitor_address_required';
    if (value.length < 3 || value.length > 200) {
      return 'visitor_address_invalid';
    }
    return null;
  }
}
