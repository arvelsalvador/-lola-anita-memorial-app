import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nita/core/gallery_assets.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/models/gallery_group.dart';

class GalleryController extends ChangeNotifier {
  static const Set<String> _pinnedGatherings = {'Jabi4.jpg', 'Jabi5.jpg'};
  static const Set<String> _pinnedRemembrances = {'Solo12.jpg'};

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
      final imagePaths = await loadGalleryPhotoPaths();

      final items = imagePaths.map((path) {
        final fileName = path.split('/').last;
        final match = RegExp(r'^[A-Za-z]+(?:_[A-Za-z]+)*').firstMatch(fileName);
        final rawGroup = match != null ? match.group(0)! : 'Other';

        GalleryGroup group = GalleryGroup.other;
        switch (rawGroup.toLowerCase()) {
          case 'bday':
            group = GalleryGroup.celebrations;
            break;
          case 'bahay':
            group = GalleryGroup.bahay;
            break;
          case 'fam':
            group = GalleryGroup.family;
            break;
          case 'hosp':
            group = GalleryGroup.care;
            break;
          case 'jabi':
            group = GalleryGroup.gatherings;
            break;
          case 'solo':
          case 'nanay':
          case 'nanay_halfbody':
            group = GalleryGroup.portraits;
            break;
          case 'final_day':
            group = GalleryGroup.remembrances;
            break;
        }

        if (_pinnedGatherings.contains(fileName)) {
          group = GalleryGroup.gatherings;
        }

        if (_pinnedRemembrances.contains(fileName)) {
          group = GalleryGroup.remembrances;
        }

        String location = 'loc_lipa';
        String date = 'date_1';
        if (group == GalleryGroup.bahay) {
          location = 'loc_bahay';
          date = 'date_2';
        } else if (group == GalleryGroup.celebrations) {
          location = 'loc_family_residence';
          date = 'date_3';
        } else if (group == GalleryGroup.family) {
          location = 'loc_batangas_province';
          date = 'date_4';
        }

        return GalleryImageItem(
          path: path,
          group: group,
          location: location,
          date: date,
        );
      }).toList();

      _images = items;
      notifyListeners();
    } catch (_) {
      _images = [];
      notifyListeners();
    }
  }

  /// First bundled audio file (sorted by name) for slideshow background
  /// music, or null when the app bundles no audio. Keeps asset manifest
  /// access and file filtering out of the widget layer.
  Future<String?> findFirstAudioAsset() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final audioFiles =
          assetManifest
              .listAssets()
              .where(
                (key) =>
                    key.startsWith('assets/audio/') &&
                    (key.endsWith('.mp3') ||
                        key.endsWith('.wav') ||
                        key.endsWith('.m4a')),
              )
              .toList()
            ..sort();
      if (audioFiles.isEmpty) return null;
      return audioFiles.first.replaceFirst('assets/', '');
    } catch (_) {
      return null;
    }
  }

  /// All bundled audio files (sorted by name), for the Highlights music
  /// picker. Unlike findFirstAudioAsset, this returns every track so the
  /// visitor can choose, not just the default.
  Future<List<String>> findAllAudioAssets() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final audioFiles =
          assetManifest
              .listAssets()
              .where(
                (key) =>
                    key.startsWith('assets/audio/') &&
                    (key.endsWith('.mp3') ||
                        key.endsWith('.wav') ||
                        key.endsWith('.m4a')),
              )
              .map((key) => key.replaceFirst('assets/', ''))
              .toList()
            ..sort();
      return audioFiles;
    } catch (_) {
      return [];
    }
  }
}
