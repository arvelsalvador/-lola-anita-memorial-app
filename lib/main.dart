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
  // Start Supabase before the first frame so the forum's startup can wait
  // for this same shared attempt. runApp is still immediate: the first
  // frame never waits for the backend, but the client is usually ready by
  // the time the forum mounts. Failures degrade to local-only mode and can
  // be retried later.
  unawaited(SupabaseConfig.initializeInBackground());
  final guideController = await GuideController.create();
  runApp(LolaApp(guideController: guideController));
}
