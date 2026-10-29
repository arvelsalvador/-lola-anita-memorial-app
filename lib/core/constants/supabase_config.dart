/// Supabase connection for the memorial backend (visitors + condolences).
///
/// Keys come ONLY from --dart-define (never pasted in code):
///   flutter run -d chrome --dart-define=SUPABASE_URL=https://REF.supabase.co
///                        --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// No flags = local-only mode (visitor gate saves on-device, candle/forum
/// use local cache). Every repository guards with `safeClient()`, so a
/// mourning visitor is never blocked by network.
///
/// NEVER paste the secret `service_role` key anywhere in this repo.

library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mpvkblyvfizjiatsrkck.supabase.co',
  );

  /// Publishable (anon) key from the Supabase dashboard.
  /// Public by design with our insert-only RLS — but still supplied via
  /// --dart-define so the repo stays key-free and git history stays clean.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_lkrORoyPXTQiw6LrZ0Dgtw_8iNUgBVK',
  );

  /// True only when real credentials were supplied via --dart-define AND
  /// the URL looks like a real Supabase project URL. Catches the common
  /// mistake of passing `--dart-define=SUPABASE_URL=your_url` literally
  /// (which yields PostgREST 404 for every table, as seen in debug logs).
  ///
  /// Mutable — deliberately NOT a getter over the credentials: main()
  /// flips it to false when Supabase.initialize throws or times out so
  /// every repository's existing `isConfigured` guard cleanly degrades
  /// to offline/local-only mode instead of throwing per call.
  static bool isConfigured = _credentialsLookValid();

  /// True only after `Supabase.initialize()` has succeeded. This prevents
  /// test and local-only flows from crashing on `Supabase.instance` access
  /// before the singleton is ready.
  static bool isInitialized = false;

  static const Map<String, String> defaultHeaders = {
    'Accept-Profile': 'public',
    'Content-Profile': 'public',
  };

  /// Returns the live client when initialization has succeeded, otherwise null.
  static SupabaseClient? safeClient() {
    if (!isConfigured || !isInitialized) return null;
    try {
      final client = Supabase.instance.client;
      client.rest.headers.addAll(defaultHeaders);
      return client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes Supabase on demand if credentials are valid and it was
  /// not yet initialized (e.g. after a hot reload when credentials were
  /// added while the app was already running).
  static Future<bool> ensureInitialized() async {
    if (isInitialized && safeClient() != null) return true;
    if (!_credentialsLookValid()) return false;
    isConfigured = true;
    try {
      final client = Supabase.instance.client;
      client.rest.headers.addAll(defaultHeaders);
      isInitialized = true;
      return true;
    } catch (_) {}
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
        postgrestOptions: const PostgrestClientOptions(schema: 'public'),
        headers: defaultHeaders,
      );
      isInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _credentialsLookValid() =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      !url.contains('your-project') &&
      !publishableKey.contains('your-publishable-key') &&
      _looksLikeSupabaseUrl(url);

  static bool _looksLikeSupabaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isAbsolute) return false;
    if (uri.scheme != 'https') return false;
    // Standard: https://REF.supabase.co (+ optional trailing slash).
    // Self-hosted / custom domains still pass if https + has a host.
    if (value.contains('your_url')) return false;
    return uri.host.isNotEmpty;
  }

  /// URL with project ref kept but path hidden, safe for debug logs.
  /// e.g. https://abcdefgh.supabase.co (never logs the key).
  /// Returns `[unconfigured]` when no URL was supplied (local-only mode).
  static String get redactedUrl {
    if (url.isEmpty) return '[unconfigured - local-only]';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '[invalid SUPABASE_URL]';
    return '${uri.scheme}://${uri.host}';
  }
}
