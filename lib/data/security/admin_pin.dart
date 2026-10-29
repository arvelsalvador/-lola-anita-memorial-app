import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/app_timeouts.dart';
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
/// Fail closed: repositories call the server RPCs only — when an RPC is
/// missing (project not yet migrated) the action fails instead of falling
/// back to a direct-table call, so the anon key can never bypass the
/// PIN/device verification (see [isRpcMissing]).
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
  /// database so server-side verification stays in sync. Fail closed:
  /// the local save happens ONLY after the server accepts the change —
  /// a failed/ambiguous server call (including a missing function on an
  /// unmigrated project or offline) leaves both sides untouched so this
  /// device and the server never drift apart on the credential.
  /// Returns true when the change is accepted.
  static Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final cleanNew = newPin.trim();
    if (!isValidPin(cleanNew) || oldPin.trim() == cleanNew) return false;
    // No server configured: nothing to verify against, the local-only
    // PIN keeps this device working (the stored default still opens
    // unmigrated databases). If the server is configured but not yet
    // initialized, fail closed rather than silently drifting from the
    // server-side verification path.
    var verified = SupabaseConfig.safeClient() == null;
    final client = SupabaseConfig.safeClient();
    if (client != null) {
      try {
        final ok = await client.rpc(
          'pakikiramay_admin_change_pin',
          params: {'p_old_pin': oldPin, 'p_new_pin': cleanNew},
        ).timeout(AppTimeouts.remote);
        // Fail closed: only a definite `true` from the PIN-verified RPC
        // counts as success; anything else (false, null, unexpected
        // shape) rejects the change and saves nothing locally.
        verified = ok is bool && ok;
        if (!verified) {
          debugPrint('AdminCredential: server rejected pin change '
              '(device-local PIN may differ from the server PIN).');
          return false;
        }
      } catch (e) {
        debugPrint(
            'AdminCredential: server pin change failed — local PIN not '
            'saved: $e');
        return false;
      }
    } else if (SupabaseConfig.isConfigured && SupabaseConfig.isInitialized) {
      debugPrint(
          'AdminCredential: configured Supabase is not initialized; refusing '
          'to silently save a PIN that cannot be verified by the server.');
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, cleanNew);
    } catch (e) {
      debugPrint('AdminCredential local pin save skipped: $e');
      return false;
    }
    return true;
  }
}

/// True when [error] means "the server function does not exist yet"
/// (project not migrated with `supabase/pakikiramay_security.sql`).
/// Checks the Postgres `undefined_function` code (42883) and the
/// PostgREST structure error (PGRST202) first; the text match is kept
/// only as a tight fallback for wrapped errors so unrelated failures
/// (network, RLS denials) never misclassify. Since the repositories are
/// fail closed, a misclassification now just surfaces an error — it can
/// never trigger a direct-table fallback.
bool isRpcMissing(Object error) {
  // PostgrestException carries the raw Postgres/PostgREST error code.
  if (error is PostgrestException) {
    final code = error.code?.toUpperCase();
    if (code != null && code.isNotEmpty) {
      return code == '42883' || code == 'PGRST202';
    }
  }
  final msg = error.toString().toLowerCase();
  return msg.contains('pgrst202') ||
      msg.contains('42883') ||
      msg.contains('could not find the function') ||
      (msg.contains('function') &&
          (msg.contains('does not exist') ||
              (msg.contains('not found') && msg.contains('schema'))));
}

/// In-memory brute-force guard for the admin PIN prompt: after
/// [maxAttempts] wrong entries the gate locks for [lockout]. State is
/// deliberately kept in memory only (never persisted) — restarting the
/// app resets it, which keeps this simple and test-friendly while still
/// making a live guessing attack slow to a crawl.
class AdminPinGate {
  AdminPinGate._();

  static const int maxAttempts = 5;
  static const Duration lockout = Duration(seconds: 60);

  static int _attempts = 0;
  static DateTime? _lockedUntil;

  /// True while the gate is locked after too many wrong attempts.
  /// Lazily clears an expired lockout so state stays self-healing.
  static bool get isLocked {
    final until = _lockedUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _lockedUntil = null;
    _attempts = 0;
    return false;
  }

  /// Seconds left on the current lockout (0 when unlocked).
  static int get secondsLeft {
    final until = _lockedUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  /// Records one attempt: failed entries count toward the lockout; a
  /// correct entry resets the counter and any active lockout.
  static void record({required bool failed}) {
    if (!failed) {
      _attempts = 0;
      _lockedUntil = null;
      return;
    }
    _attempts++;
    if (_attempts >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockout);
      _attempts = 0;
    }
  }

  /// Test/reset helper: wipes all gate state.
  static void reset() {
    _attempts = 0;
    _lockedUntil = null;
  }
}
