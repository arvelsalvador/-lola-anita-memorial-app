import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/supabase_config.dart';

/// The family admin PIN, this app's single source of truth.
///
/// Security model (after `supabase/pakikiramay_security.sql` runs): the PIN
/// is verified INSIDE the database by PIN-parameterized security-definer
/// RPCs. Every privileged action (edit/delete/dismiss/list private rows)
/// sends this PIN to Supabase over HTTPS and the server decides. The PIN
/// is never hard-trusted client-side; the same value lives here, in the
/// admin settings, and (bcrypt-hashed) in `app_admin_secret`.
///
/// Deploy order does not matter: repositories first ask the server functions
/// and fall back to the legacy direct-table calls when the project has not
/// been migrated yet (see [isRpcMissing]).
class AdminCredential {
  AdminCredential._();

  /// Built-in default PIN, replaced on-device and on the server.
  static const String defaultPin = '538523';

  static const String prefsKey = 'admin_custom_pin';

  /// The PIN that currently opens the admin page: the family's own PIN
  /// when one was saved on this device, otherwise the built-in default.
  static Future<String> effectivePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey)?.trim() ?? '';
      if (RegExp(r'^\d{6}$').hasMatch(saved)) return saved;
    } catch (_) {}
    return defaultPin;
  }

  /// True when [value] is a 6-digit PIN.
  static bool isValidPin(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim());

  /// Persists the family PIN on-device AND updates the bcrypt hash in the
  /// database so server-side verification stays in sync. The local save
  /// happens only after the server accepts (or is not reachable for
  /// verification on an unmigrated project). Returns true when the change
  /// is accepted; a server-side rejection saves nothing.
  static Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final cleanNew = newPin.trim();
    if (!isValidPin(cleanNew) || oldPin.trim() == cleanNew) return false;
    if (SupabaseConfig.isConfigured) {
      try {
        final ok = await Supabase.instance.client.rpc(
          'pakikiramay_admin_change_pin',
          params: {'p_old_pin': oldPin, 'p_new_pin': cleanNew},
        ).timeout(const Duration(seconds: 8));
        if (ok is bool) {
          if (!ok) {
            debugPrint('AdminCredential: server rejected pin change '
                '(device-local PIN may differ from the server PIN).');
            return false;
          }
        }
        // Non-bool (unmigrated project returning nothing useful): keep
        // the local change so the device behaves as before.
      } catch (e) {
        // Function missing (project not yet migrated): the local PIN keeps
        // working; the server still holds the seeded default until the
        // SQL script runs.
        if (!isRpcMissing(e)) {
          debugPrint('AdminCredential: server pin change skipped: $e');
        }
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, cleanNew);
    } catch (e) {
      debugPrint('AdminCredential local pin save skipped: $e');
    }
    return true;
  }
}

/// True when [error] means "the server function does not exist yet"
/// (project not migrated with `supabase/pakikiramay_security.sql`).
/// Repos use this to fall back to the legacy direct-table path so an
/// unmigrated project keeps working.
bool isRpcMissing(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('pgrst202') ||
      msg.contains('could not find the function') ||
      msg.contains('function') && msg.contains('not found');
}
