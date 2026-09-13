import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:nita/core/localization/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop video backend: official video_player has no Windows/Linux
  // implementation, so fvp (FFmpeg/libmdk) fills in there only — Android,
  // iOS, macOS and web keep their official implementations.
  fvp.registerWith(options: {'platforms': ['windows', 'linux']});
  if (kDebugMode) {
    LanguageProvider.debugCheckTranslationKeysMatch();
  }
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Graceful fallback if Firebase is not yet configured with options
  }
  runApp(const LolaApp());
}
