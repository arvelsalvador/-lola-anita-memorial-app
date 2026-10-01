import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/supabase_config.dart';

/// Mensahe saver for the Pakikiramay tab: name (from splash gate) +
/// message, stored in `pakikiramay_messages`.
///
/// Local-first like [VisitorRepository]: the candle always lights, the
/// insert runs in the background with a short timeout and never throws
/// to the UI — a mourning visitor is never blocked by network.
/// Table is `id uuid, name text, message text, approved bool,
/// created_at timestamptz`. Only `name` + `message` are sent; `approved`
/// and `created_at` are DB defaults. No `lang` column exists on this
/// table (splash `lang` lives on `visitors`).
class CondolenceRepository {
  const CondolenceRepository();

  static const String table = 'pakikiramay_messages';
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

    if (!SupabaseConfig.isConfigured) return false;
    try {
      final client = Supabase.instance.client;
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
}
