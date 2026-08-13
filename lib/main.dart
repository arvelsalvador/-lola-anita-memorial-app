import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nita/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Graceful fallback if Firebase is not yet configured with options
  }
  runApp(const LolaApp());
}
