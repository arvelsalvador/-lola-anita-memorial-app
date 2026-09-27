import 'package:flutter/material.dart';

/// Candle state for the Condolences (Pakikiramay) tab.
/// Split out of WordsController so each page owns its controller:
/// Words = family quotes, Condolences = candle lighting.
class CondolencesController extends ChangeNotifier {
  /// Seed so a fresh visit never reads as zero — the count represents
  /// "candles lit before you arrived". Session-only (see [lightCandle]).
  static const int initialCandleCount = 124;

  int _localCount = initialCandleCount;
  bool _lit = false;
  bool _loading = false;
  bool _disposed = false;

  int get localCount => _localCount;
  bool get lit => _lit;
  bool get loading => _loading;

  /// Local-only for now (no Firebase): session candle count.
  /// Starts at 124 each launch, +1 when lit. Shared Firestore count
  /// can be re-added later behind a flag without changing the UI,
  /// which reads [localCount] only.
  Future<void> lightCandle() async {
    if (_lit || _loading || _disposed) return;
    _loading = true;
    notifyListeners();
    // Tiny delay so the disabled button state is visible, then light.
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      if (_disposed) return;
    }
    if (_disposed) return;
    _lit = true;
    _localCount++;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
