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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nita/core/constants/app_timeouts.dart';

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
  /// Mutable — deliberately NOT a getter over the credentials: the shared
  /// background initializer flips it to false when Supabase.initialize
  /// throws or times out so every repository's existing `isConfigured`
  /// guard cleanly degrades to offline/local-only mode instead of throwing
  /// per call.
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

  /// The one initialization attempt for this app session. Concurrent
  /// callers (startup, visitor sync, any repository) share this future
  /// instead of racing to initialize the singleton twice. Cleared again
  /// when an attempt fails so a later retry can make a fresh attempt.
  static Future<bool>? _initFuture;

  /// True when the build carries usable Supabase credentials, regardless of
  /// whether initialization has succeeded yet. Lets startup code tell
  /// "offline by configuration" apart from "offline because the network
  /// attempt failed and is worth retrying".
  static bool get hasCredentials => _credentialsLookValid();

  /// The shared startup attempt, or null when none is running. The forum
  /// uses this to wait for the app-wide initialization instead of starting
  /// its own or silently falling back to cache-only mode.
  static Future<bool>? get initializationFuture => _initFuture;

  static bool _initializationAttempted = false;

  /// True once startup called [initializeInBackground], even if that
  /// attempt later failed and was cleared. Distinguishes a real app that
  /// should keep retrying from a test/local-only process that never wanted
  /// the network at all.
  static bool get initializationAttempted => _initializationAttempted;

  /// Starts Supabase initialization without blocking the caller. Call this
  /// once from `main()` right before `runApp`; the first frame no longer
  /// waits for the backend (up to [AppTimeouts.startup]).
  ///
  /// Repositories call [ensureInitialized] before touching the client, so
  /// they wait for this same attempt instead of starting another one.
  static Future<bool> initializeInBackground() {
    _initializationAttempted = true;
    if (isInitialized && safeClient() != null) {
      return Future<bool>.value(true);
    }
    final existing = _initFuture;
    if (existing != null) return existing;
    final future = _initialize();
    _initFuture = future;
    // Never cache a failed attempt for the whole session: startup, a Retry
    // button, app resume, or the forum's reconnect backoff get a fresh
    // chance instead of instantly returning the old false forever.
    unawaited(future.then((ok) {
      if (!ok && identical(_initFuture, future)) {
        _initFuture = null;
      }
    }));
    return future;
  }

  /// Initializes Supabase on demand if credentials are valid and it was
  /// not yet initialized (e.g. after a hot reload when credentials were
  /// added while the app was already running).
  ///
  /// Shares [initializeInBackground]'s future, so this never starts a
  /// second `Supabase.initialize` while the first is still running.
  static Future<bool> ensureInitialized() => initializeInBackground();

  static Future<bool> _initialize() async {
    if (!_credentialsLookValid()) {
      debugPrint(
        'Supabase unconfigured — running local-only. '
        'To sync: flutter run --dart-define=SUPABASE_URL=https://REF.supabase.co '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...',
      );
      return false;
    }
    isConfigured = true;
    // Hot reload / re-entry: the singleton may already be alive.
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
      ).timeout(AppTimeouts.startup);
      isInitialized = true;
      debugPrint('Supabase init completed ($redactedUrl)');
      return true;
    } catch (e) {
      isInitialized = false;
      // Init failed (bad URL / network / timeout): degrade cleanly to
      // offline mode. Every repository checks isConfigured before touching
      // the client, so flipping it false keeps the app usable.
      isConfigured = false;
      debugPrint('Supabase init skipped ($redactedUrl $e)');
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
