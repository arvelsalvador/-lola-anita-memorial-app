import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nita/data/gallery/gallery_repository.dart';
import 'package:nita/models/gallery_model.dart';

/// Thin state holder for the gallery tab.
///
/// Classification/parsing lives in [GalleryRepository]; this class only
/// owns loaded items + unlock consent state.
class GalleryController extends ChangeNotifier {
  List<GalleryImageItem>? _images;

  /// Null until the asset manifest has been read.
  List<GalleryImageItem>? get images => _images;

  /// Photo paths the visitor has consented to see (the "Last Day"
  /// remembrances stay blurred until tapped). Single source of truth for
  /// unlock state, shared by the grid and the lightbox.
  final Set<String> _unlocked = {};

  Set<String> get unlockedPaths => Set.unmodifiable(_unlocked);

  bool isUnlocked(String path) => _unlocked.contains(path);

  void unlock(String path) {
    if (_unlocked.add(path)) notifyListeners();
  }

  void resetUnlocked() {
    if (_unlocked.isEmpty) return;
    _unlocked.clear();
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final imagePaths = await GalleryRepository.loadImagePaths().timeout(
        const Duration(seconds: 10),
      );
      _images = GalleryRepository.toItems(imagePaths);
      notifyListeners();
    } catch (e) {
      debugPrint('[Gallery] load failed, showing empty: $e');
      _images = [];
      notifyListeners();
    }
  }

  /// First bundled audio file (sorted by name) for slideshow background
  /// music, or null when the app bundles no audio.
  Future<String?> findFirstAudioAsset() =>
      GalleryRepository.findFirstAudioAsset();

  /// All bundled audio files (sorted by name), for the Highlights music
  /// picker.
  Future<List<String>> findAllAudioAssets() =>
      GalleryRepository.findAllAudioAssets();
}
