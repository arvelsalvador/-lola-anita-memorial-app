import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
