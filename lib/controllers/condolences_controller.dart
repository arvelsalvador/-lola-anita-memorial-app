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

  /// Shared Supabase state. Null = not yet loaded / offline.
  /// `recentNames == null` means offline (hide list, show offline note);
  /// empty list means online with no candles yet.
  int? _remoteCount;
  List<String>? _recentNames;
  bool _listLoading = false;

  int get localCount => _localCount;
  bool get lit => _lit;
  bool get loading => _loading;
  int? get remoteCount => _remoteCount;
  List<String>? get recentNames => _recentNames;
  bool get listLoading => _listLoading;

  /// Count shown in the UI: shared number when available,
  /// otherwise the 124 seed (never zero, never flickers).
  int get displayCount => _remoteCount ?? _localCount;

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

  void setListLoading(bool value) {
    if (_disposed) return;
    _listLoading = value;
    notifyListeners();
  }

  /// Name of this session's candle while its save is unconfirmed.
  /// Guards the lit-during-load race: a stale 0/[] snapshot arriving
  /// after lighting must not erase your own candle.
  String? _pendingName;

  /// Applies a fetched remote snapshot. Nulls mean offline — keeps
  /// previous values so the UI falls back gracefully. Pass
  /// `markSynced: true` for the refresh after our own save succeeds
  /// (server now includes us); other loads re-apply the pending
  /// overlay so your candle survives slow/stale snapshots.
  void applyRemote({int? count, List<String>? names, bool markSynced = false}) {
    if (_disposed) return;
    if (markSynced) _pendingName = null;
    if (count != null) _remoteCount = count;
    // `names` null = offline (leave as null = hide list);
    // non-null (even empty) = online snapshot.
    _recentNames = names;
    if (!markSynced) _overlayPending();
    _listLoading = false;
    notifyListeners();
  }

  /// Records this session's light for overlay onto remote snapshots
  /// until the post-save refresh confirms it. Safe to call when
  /// offline (pending simply has nothing to overlay onto yet).
  void noteOwnLight(String name) {
    if (_disposed) return;
    final clean = name.trim();
    _pendingName = clean.isEmpty ? null : clean;
    _overlayPending();
    notifyListeners();
  }

  void _overlayPending() {
    if (_pendingName == null || _disposed) return;
    if (_remoteCount != null) _remoteCount = _remoteCount! + 1;
    if (_recentNames != null && !_recentNames!.contains(_pendingName)) {
      _recentNames = [_pendingName!, ..._recentNames!];
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
