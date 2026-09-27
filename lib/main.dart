import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
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
    },
  );
  if (kDebugMode) {
    LanguageProvider.debugCheckTranslationKeysMatch();
  }
  // Local-only for now: no Firebase init. Candle count is session-only,
  // messages show thanks without a backend (see WordsController).
  runApp(const LolaApp());
}
