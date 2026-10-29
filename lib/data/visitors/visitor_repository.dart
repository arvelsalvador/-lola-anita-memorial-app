import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nita/core/constants/app_timeouts.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/data/security/admin_pin.dart';
import 'package:nita/models/admin_visitor_model.dart';

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

  /// Saves the visitor on-device only. Fast and always succeeds, so the
  /// gate can let the visitor in immediately without waiting for network.
  Future<void> saveVisitorLocal({
    required String name,
    required String address,
  }) async {
    final cleanName = name.trim();
    final cleanAddress = address.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, cleanName);
    await prefs.setString(_kAddress, cleanAddress);
    await prefs.setString(_kSavedAt, DateTime.now().toIso8601String());
  }

  /// Uploads the visitor row to Supabase. Waits for the app's shared
  /// background initialization (started in `main()`) instead of forcing a
  /// second one. Never throws; returns true when the insert succeeded.
  Future<bool> syncVisitor({
    required String name,
    required String address,
    String lang = 'tl',
  }) async {
    if (!SupabaseConfig.isConfigured) return false;
    final ready = await SupabaseConfig.ensureInitialized();
    if (!ready) return false;
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    try {
      await client
          .from(table)
          .insert({
            'name': name.trim(),
            'address': address.trim(),
            'lang': lang,
          })
          .timeout(AppTimeouts.remote);
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

  /// Local save + best-effort remote sync in one await. Kept for callers
  /// and tests that do not need the split fast path; the splash gate uses
  /// [saveVisitorLocal] + [syncVisitor] so entry never waits on network.
  /// Returns true when the remote insert succeeded.
  Future<bool> saveVisitor({
    required String name,
    required String address,
    String lang = 'tl',
  }) async {
    await saveVisitorLocal(name: name, address: address);
    return syncVisitor(name: name, address: address, lang: lang);
  }

  static const String table = 'visitors';

  /// How many visitors entered the app (rows in [table]).
  /// Runs through the aggregate RPC `pakikiramay_candle_count()` — the
  /// table is insert-only for the anon key after the security migration,
  /// so there is deliberately NO direct-table fallback (fail closed).
  /// Returns null when offline/unconfigured/denied (caller shows
  /// fallback). Never throws.
  Future<int?> fetchVisitorCount() async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return null;
    try {
      final count = await client
          .rpc('pakikiramay_candle_count')
          .timeout(AppTimeouts.remote);
      if (count is num) return count.toInt();
      return int.tryParse('$count');
    } catch (e) {
      debugPrint(
        'VisitorRepository: visitor count skipped '
        '(${SupabaseConfig.redactedUrl} $e)',
      );
      return null;
    }
  }

  /// Names-only list of who visited, newest first.
  /// Uses the narrow RPC `pakikiramay_candle_names()` — names only;
  /// addresses and lang stay inside the server. There is deliberately NO
  /// direct-table fallback (fail closed: the table is private after the
  /// security migration). Returns null when offline/unconfigured/denied,
  /// an empty list when online with no rows yet. Never throws.
  Future<List<String>?> fetchVisitorNames({int limit = 50}) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return null;
    try {
      final rows = await client
          .rpc('pakikiramay_candle_names', params: {'p_limit': limit})
          .timeout(AppTimeouts.remote);
      return _parseNameRows(rows as List);
    } catch (e) {
      debugPrint(
        'VisitorRepository: visitor names skipped '
        '(${SupabaseConfig.redactedUrl} $e)',
      );
      return null;
    }
  }

  /// Row mapper for the RPC result.
  List<String> _parseNameRows(List rows) {
    final names = <String>[];
    for (final row in rows) {
      final raw = (row as Map)['name'];
      final name = (raw is String ? raw : '').trim();
      if (name.isEmpty) continue;
      names.add(name.length > 50 ? name.substring(0, 50) : name);
    }
    return names;
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

  /// Full visitor rows for the family admin page, newest first.
  /// PIN-verified RPC only (`pakikiramay_admin_list_visitors` — a wrong
  /// PIN raises 403). There is deliberately NO anon SELECT fallback (fail
  /// closed: visitor rows are private after the security migration).
  /// Empty when offline/unconfigured/denied/RPC missing. Never throws.
  Future<List<AdminVisitor>> fetchAdminVisitors({int limit = 200}) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return [];
    final pin = await AdminCredential.effectivePin();
    try {
      final rows = await client
          .rpc('pakikiramay_admin_list_visitors', params: {
        'p_pin': pin,
        'p_limit': limit,
      }).timeout(AppTimeouts.remote);
      return _parseVisitorRows(rows as List);
    } catch (e) {
      debugPrint('VisitorRepository fetchAdminVisitors skipped: $e');
      return [];
    }
  }

  /// Row mapper for the RPC result.
  List<AdminVisitor> _parseVisitorRows(List rows) {
    final out = <AdminVisitor>[];
    for (final row in rows) {
      final m = row as Map;
      DateTime at = DateTime.now();
      final rawAt = m['created_at'];
      if (rawAt is String) at = DateTime.tryParse(rawAt) ?? at;
      out.add(AdminVisitor(
        id: m['id']?.toString() ?? '',
        name: (m['name'] as String? ?? '').trim(),
        address: (m['address'] as String? ?? '').trim(),
        lang: (m['lang'] as String? ?? '').trim(),
        createdAt: at,
      ));
    }
    return out.where((v) => v.id.isNotEmpty).toList();
  }

  /// Updates a visitor's name + address (family admin). PIN-verified RPC
  /// only — there is deliberately NO anon UPDATE fallback (fail closed).
  /// Returns true when saved. Never throws.
  Future<bool> updateVisitor({
    required String id,
    required String name,
    required String address,
  }) async {
    final cleanName = name.trim();
    final cleanAddress = address.trim();
    if (id.isEmpty || cleanName.isEmpty) return false;
    if (validateAddress(cleanAddress) != null) return false;
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_update_visitor',
            params: {
              'p_pin': pin,
              'p_id': id,
              'p_name': cleanName,
              'p_address': cleanAddress,
            },
          ).timeout(AppTimeouts.remote)) as bool?;
      return ok ?? false;
    } catch (e) {
      debugPrint('VisitorRepository updateVisitor skipped: $e');
      return false;
    }
  }

  /// Deletes a visitor row (family admin). PIN-verified RPC only — there
  /// is deliberately NO anon DELETE fallback (fail closed). Returns true
  /// when deleted. Never throws.
  Future<bool> deleteVisitor(String id) async {
    if (id.isEmpty) return false;
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_delete_visitor',
            params: {'p_pin': pin, 'p_id': id},
          ).timeout(AppTimeouts.remote)) as bool?;
      return ok ?? false;
    } catch (e) {
      debugPrint('VisitorRepository deleteVisitor skipped: $e');
      return false;
    }
  }
}
