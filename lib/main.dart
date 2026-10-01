import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop video backend: official video_player has no Windows/Linux
  // implementation, so fvp (FFmpeg/libmdk) fills in there only — Android,
  // iOS, macOS and web keep their official implementations.
  fvp.registerWith(
    options: {
      'platforms': ['windows', 'linux'],
      // Windows safety: force FFmpeg software decoding for the candle clip.
      // The default D3D11 hardware-decoder texture interop crashes the
      // Flutter desktop engine on some Intel iGPUs (native 0xc0000005 in
      // fvp.dll at startup, reported as "Lost connection to device").
      // candle.mp4 is a tiny 200px medallion loop, so SW decode is cheap.
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
      ).timeout(const Duration(seconds: 10));
      debugPrint(
        'Supabase init completed (${SupabaseConfig.redactedUrl})',
      );
    } catch (e) {
      debugPrint(
        'Supabase init skipped (${SupabaseConfig.redactedUrl} $e)',
      );
    }
  } else {
    debugPrint(
      'Supabase unconfigured — running local-only. '
      'Pass real --dart-define=SUPABASE_URL=https://<ref>.supabase.co '
      '(not "your_url").',
    );
  }
  runApp(const LolaApp());
}
