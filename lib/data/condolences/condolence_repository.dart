import 'package:flutter/foundation.dart';

import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/data/security/admin_pin.dart';
import 'package:nita/models/admin_candle_message_model.dart';

/// Private mensahe saver for the candle (Field 1): name (from splash
/// gate) + message, stored in `candle_messages`.
///
/// Private by design: anon INSERT only, no public SELECT — family reads
/// via the PIN-verified admin RPC (`pakikiramay_admin_list_candles`)
/// after `supabase/pakikiramay_security.sql` runs. The public board
/// (`pakikiramay_messages` via ForumRepository) never sees these rows.
///
/// Local-first like [VisitorRepository]: the candle always lights, the
/// insert runs in the background with a short timeout and never throws
/// to the UI — a mourning visitor is never blocked by network.
/// Table is `id uuid, name text, message text,
/// created_at timestamptz`. Only `name` + `message` are sent; `id`
/// and `created_at` are DB defaults with 1–500 char message check.
class CondolenceRepository {
  const CondolenceRepository();

  static const String table = 'candle_messages';
  static const int maxMessageLength = 500;

  /// Message rule: required, 1–500 chars after trim.
  /// Returns a translation key, or null when valid.
  static String? validateMessage(String input) {
    final value = input.trim();
    if (value.isEmpty) return 'candle_message_required';
    if (value.length > maxMessageLength) return 'candle_message_too_long';
    return null;
  }

  /// Saves name + message in background. Returns true when the remote
  /// insert succeeded, false when skipped (unconfigured/invalid/offline).
  /// Never throws.
  Future<bool> saveMessage({required String name, required String message}) async {
    final cleanName = name.trim().isEmpty ? 'Anonymous' : name.trim();
    final cleanMessage = message.trim();
    if (validateMessage(cleanMessage) != null) return false;

    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    try {
      await client
          .from(table)
          .insert({'name': cleanName, 'message': cleanMessage}).timeout(
            const Duration(seconds: 8),
          );
      return true;
    } catch (e) {
      // Offline / RLS / table-missing / Data API disabled: candle already
      // lit locally. 404 Not Found usually means wrong SUPABASE_URL or
      // the table is not exposed to the Data API.
      // Never rethrow to a mourning visitor.
      debugPrint(
        'CondolenceRepository: remote save to $table skipped '
        '(${SupabaseConfig.redactedUrl} $e) '
        'hint: real https URL, Data API enabled, anon INSERT policy.',
      );
      return false;
    }
  }

  /// Private candle rows for the family admin page, newest first.
  /// PIN-verified RPC (`pakikiramay_admin_list_candles`) only — the table
  /// is insert-only for the anon key after the security migration, so
  /// there is deliberately NO direct-table fallback (fail closed).
  /// Empty when offline/unconfigured/wrong-PIN/RPC missing. Never throws.
  Future<List<AdminCandleMessage>> fetchAdminMessages({int limit = 200}) async {
    final client = SupabaseConfig.safeClient();
    if (client == null) return [];
    final pin = await AdminCredential.effectivePin();
    try {
      final rows = await client
          .rpc('pakikiramay_admin_list_candles', params: {
        'p_pin': pin,
        'p_limit': limit,
      }).timeout(const Duration(seconds: 8));
      return _parseCandleRows(rows as List);
    } catch (e) {
      debugPrint('CondolenceRepository fetchAdminMessages skipped: $e');
      return [];
    }
  }

  /// Shared row mapper for the RPC result.
  List<AdminCandleMessage> _parseCandleRows(List rows) {
    final out = <AdminCandleMessage>[];
    for (final row in rows) {
      final m = row as Map;
      DateTime at = DateTime.now();
      final rawAt = m['created_at'];
      if (rawAt is String) at = DateTime.tryParse(rawAt) ?? at;
      out.add(AdminCandleMessage(
        id: m['id']?.toString() ?? '',
        name: (m['name'] as String? ?? '').trim(),
        message: (m['message'] as String? ?? '').trim(),
        createdAt: at,
      ));
    }
    return out.where((c) => c.id.isNotEmpty).toList();
  }

  /// Updates a private message (family admin). PIN-verified RPC only —
  /// there is deliberately NO anon UPDATE fallback (fail closed).
  /// Returns true when saved. Never throws.
  Future<bool> updateMessage({
    required String id,
    required String message,
  }) async {
    final clean = message.trim();
    if (id.isEmpty || validateMessage(clean) != null) return false;
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_edit_candle',
            params: {'p_pin': pin, 'p_id': id, 'p_message': clean},
          ).timeout(const Duration(seconds: 8))) as bool?;
      return ok ?? false;
    } catch (e) {
      debugPrint('CondolenceRepository updateMessage skipped: $e');
      return false;
    }
  }

  /// Deletes a private message (family admin). PIN-verified RPC only —
  /// there is deliberately NO anon DELETE fallback (fail closed).
  /// Returns true when deleted. Never throws.
  Future<bool> deleteMessage(String id) async {
    if (id.isEmpty) return false;
    final client = SupabaseConfig.safeClient();
    if (client == null) return false;
    final pin = await AdminCredential.effectivePin();
    try {
      final ok = (await client.rpc(
            'pakikiramay_admin_delete_candle',
            params: {'p_pin': pin, 'p_id': id},
          ).timeout(const Duration(seconds: 8))) as bool?;
      return ok ?? false;
    } catch (e) {
      debugPrint('CondolenceRepository deleteMessage skipped: $e');
      return false;
    }
  }
}

