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

  /// True once the pending +1 has been added onto a count value.
  /// Applied at most once per pending candle — repeated refreshes
  /// (especially offline ones that keep the previous count value)
  /// must not inflate the number again. Reset when the pending is
  /// cleared (save failed) or synced (server now includes us).
  bool _overlayCounted = false;

  /// True when the current `_remoteCount` value still carries the
  /// pending +1, so a failed save can subtract it back out. A fresh
  /// snapshot (`count != null`) always clears this — the new value is
  /// raw and un-overlaid until re-applied.
  bool _overlayInCount = false;

  /// Applies a fetched remote snapshot. Nulls mean offline — keeps
  /// previous values so the UI falls back gracefully. Pass
  /// `markSynced: true` for the refresh after our own save succeeds
  /// (server now includes us); other loads keep the pending overlay —
  /// the name stays pinned on every snapshot, the +1 is added at most
  /// once so slow saves + repeated refreshes can't inflate the count.
  void applyRemote({int? count, List<String>? names, bool markSynced = false}) {
    if (_disposed) return;
    if (markSynced) {
      _pendingName = null;
      _overlayCounted = false;
      _overlayInCount = false;
    }
    if (count != null) {
      _remoteCount = count;
      // A fresh snapshot is a raw server value — any earlier overlay is
      // gone. _overlayPending() may add the +1 back (once only).
      _overlayInCount = false;
    }
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
    // A fresh pending candle: its +1 has not been applied anywhere yet.
    _overlayCounted = false;
    _overlayInCount = false;
    _overlayPending();
    notifyListeners();
  }

  /// The background save failed — the server never received this
  /// candle, so drop the pending overlay instead of leaving a fake
  /// candle in the shared list forever: the +1 comes back out of the
  /// count (only if the current value still carries it) and the pinned
  /// name leaves the top of the list. The local lit state is untouched
  /// (the candle did light on this device).
  void clearPendingLight() {
    if (_disposed) return;
    if (_overlayInCount && _remoteCount != null && _remoteCount! > 0) {
      _remoteCount = _remoteCount! - 1;
    }
    _overlayInCount = false;
    _overlayCounted = false;
    if (_pendingName != null) {
      // Only unpin the entry we prepended — a same-named visitor deeper
      // in a fresh snapshot is real and must stay.
      if (_recentNames != null &&
          _recentNames!.isNotEmpty &&
          _recentNames!.first == _pendingName) {
        _recentNames = _recentNames!.sublist(1);
      }
      _pendingName = null;
      notifyListeners();
    }
  }

  void _overlayPending() {
    if (_pendingName == null || _disposed) return;
    // +1 at most once per pending candle (until cleared or synced):
    // every non-synced refresh used to re-add it, inflating the count.
    if (!_overlayCounted && _remoteCount != null) {
      _remoteCount = _remoteCount! + 1;
      _overlayCounted = true;
      _overlayInCount = true;
    }
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
