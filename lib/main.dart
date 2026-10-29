import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nita/core/constants/app_timeouts.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop video backend: official video_player has no Windows/Linux
  // implementation, so fvp (FFmpeg/libmdk) fills in there only — Android,
  // iOS, macOS and web keep their official implementations.
  fvp.registerWith(
    options: {
      'platforms': ['windows', 'linux'],
      // Requires fvp >= 0.39.1 on Windows: 0.38.x crashed the native
      // engine (access violation, reported as "Lost connection to
      // device") when the first video texture was created.
      // Software decoding is kept for the small candle/medallion loop.
      'video.decoders': ['FFmpeg'],
    },
  );
  if (kDebugMode) {
    LanguageProvider.debugCheckTranslationKeysMatch();
  }
  // Local-only for now when Supabase is unconfigured: visitor gate saves
  // on-device and entry never blocks. When URL + anon key are supplied
  // (see supabase_config.dart), remote sync activates in background.
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        postgrestOptions: const PostgrestClientOptions(schema: 'public'),
        headers: SupabaseConfig.defaultHeaders,
      ).timeout(AppTimeouts.startup);
      SupabaseConfig.isInitialized = true;
      debugPrint(
        'Supabase init completed (${SupabaseConfig.redactedUrl})',
      );
    } catch (e) {
      SupabaseConfig.isInitialized = false;
      debugPrint(
        'Supabase init skipped (${SupabaseConfig.redactedUrl} $e)',
      );
      // Init failed (bad URL / network / 10s timeout): degrade cleanly
      // to offline mode. Every repository checks SupabaseConfig.
      // isConfigured before touching the client, so flipping it false
      // keeps app startup going instead of throwing per call forever.
      SupabaseConfig.isConfigured = false;
    }
  } else {
    debugPrint(
      'Supabase unconfigured — running local-only. '
      'To sync: flutter run --dart-define=SUPABASE_URL=https://REF.supabase.co '
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...',
    );
  }
  final guideController = await GuideController.create();
  runApp(LolaApp(guideController: guideController));
}
