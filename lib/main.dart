import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:nita/core/constants/supabase_config.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop video backend: official video_player has no Windows/Linux
  // implementation, so fvp (FFmpeg/libmdk) fills in there only — Android,
  // iOS, macOS and web keep their official implementations.
  if (!kIsWeb) fvp.registerWith(
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
  // Start Supabase in the background so the first frame is never blocked
  // by the backend (previously up to 10s before runApp). Repositories await
  // this same shared future before using the client; if it fails, the app
  // degrades cleanly to local-only mode.
  final guideController = await GuideController.create();
  runApp(LolaApp(guideController: guideController));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(SupabaseConfig.initializeInBackground());
  });
}
