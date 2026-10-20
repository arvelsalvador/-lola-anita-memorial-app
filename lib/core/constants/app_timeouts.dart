/// Single source for network / async timeouts.
///
/// Problem before: `Duration(seconds: 8/10/5/3)` was hardcoded in 30+
/// places across repositories, controllers, and widgets — changing it
/// meant hunting every file.
///
/// Use:
/// - [remote] (8s): all Supabase calls (fetch/insert/RPC).
/// - [manifest] (10s): asset-manifest reads (gallery, startup).
/// - [quick] (5s): small secondary fetches (replies fallback).
/// - [local] (3s): local-only reads (SharedPreferences via repo).
/// - [startup] (10s): Supabase.initialize in main().
///
/// UI durations (slideshow 5s, splash 12s, lockouts, cooldowns) are
/// NOT here on purpose — those are UX timing, not network timeouts.
class AppTimeouts {
  AppTimeouts._();

  static const Duration remote = Duration(seconds: 8);
  static const Duration manifest = Duration(seconds: 10);
  static const Duration quick = Duration(seconds: 5);
  static const Duration local = Duration(seconds: 3);
  static const Duration startup = Duration(seconds: 10);
  static const Duration mediaInit = Duration(seconds: 8);
}
