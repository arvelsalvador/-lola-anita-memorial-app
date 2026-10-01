/// Supabase connection for the memorial backend (visitors + condolences).
///
/// OPTION A (chosen): paste values once below — no --dart-define needed.
/// 1. Supabase dashboard > your project Anita-Memorial_Database
/// 2. Bottom-left gear (Project Settings) > Data API
/// 3. Copy "Project URL" (https://xxx.supabase.co) -> _defaultUrl
/// 4. Copy "publishable / anon" key (sb_publishable_...) -> _defaultKey
/// 5. Save + `flutter run -d chrome` (no extra flags).
/// --dart-define still wins if supplied. Unconfigured = local-only.
class SupabaseConfig {
  SupabaseConfig._();

  // ==== PASTE HERE (Option A) ====
  static const String _defaultUrl = 'https://mpvkblyvfizjiatsrkck.supabase.co';
  static const String _defaultKey =
      'sb_publishable_lkrORoyPXTQiw6LrZ0Dgtw_8iNUgBVK';
  // ===============================

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  /// Publishable (anon) key from the Supabase dashboard.
  /// Public by design with our insert-only RLS — safe to commit.
  /// NEVER paste the secret `service_role` key here.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultKey,
  );

  /// True only when real credentials were supplied AND the URL looks
  /// like a real Supabase project URL. Catches the common mistake of
  /// passing `--dart-define=SUPABASE_URL=your_url` literally (which
  /// yields PostgREST 404 for every table, as seen in debug logs).
  static bool get isConfigured =>
      !url.contains('your-project') &&
      !publishableKey.contains('your-publishable-key') &&
      _looksLikeSupabaseUrl(url);

  static bool _looksLikeSupabaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isAbsolute) return false;
    if (uri.scheme != 'https') return false;
    // Standard: https://<ref>.supabase.co (+ optional trailing slash).
    // Self-hosted / custom domains still pass if https + has a host.
    if (value.contains('your_url')) return false;
    return uri.host.isNotEmpty;
  }

  /// URL with project ref kept but path hidden, safe for debug logs.
  /// e.g. https://abcdefgh.supabase.co (never logs the key).
  static String get redactedUrl {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '<invalid SUPABASE_URL>';
    return '${uri.scheme}://${uri.host}';
  }
}
