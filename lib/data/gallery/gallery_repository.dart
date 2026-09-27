import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nita/core/utils/gallery_assets.dart';
import 'package:nita/models/gallery_model.dart';

/// Data-layer mapping for gallery assets.
///
/// Owns filename → [GalleryGroup] / location / date rules plus asset
/// manifest scanning, so [GalleryController] stays a thin
/// `ChangeNotifier` (unlock state + loaded items only).
class GalleryRepository {
  static const Set<String> pinnedGatherings = {'Jabi4.jpg', 'Jabi5.jpg'};
  static const Set<String> pinnedRemembrances = {'Solo12.jpg'};

  static final RegExp _groupPrefix = RegExp(r'^[A-Za-z]+(?:_[A-Za-z]+)*');

  /// Classify a single asset path (e.g. `assets/images/gallery/Bday/Bday1.jpg`).
  static GalleryGroup classifyGroup(String path) {
    final fileName = path.split('/').last;
    final match = _groupPrefix.firstMatch(fileName);
    // match != null is checked first, so group(0) can't be null here.
    final rawGroup = match != null ? match.group(0) ?? 'Other' : 'Other';

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
      case 'after':
        // "After death ..." photos belong with the Last Day remembrances.
        group = GalleryGroup.remembrances;
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

    if (pinnedGatherings.contains(fileName)) {
      group = GalleryGroup.gatherings;
    }
    if (pinnedRemembrances.contains(fileName)) {
      group = GalleryGroup.remembrances;
    }
    return group;
  }

  /// TODO(family): all four `loc_*` keys currently resolve to the same
  /// address string, and `date_1..4` are unlabeled placeholders assigned
  /// per-group below. Do not treat these as precise photo metadata until
  /// the family labels which photo/event each date/location belongs to.
  /// When that lands, replace this group-based fallback with per-photo data.
  static String locationFor(GalleryGroup group) {
    if (group == GalleryGroup.bahay) return 'loc_bahay';
    if (group == GalleryGroup.celebrations) return 'loc_family_residence';
    if (group == GalleryGroup.family) return 'loc_batangas_province';
    return 'loc_lipa';
  }

  static String dateFor(GalleryGroup group) {
    if (group == GalleryGroup.bahay) return 'date_2';
    if (group == GalleryGroup.celebrations) return 'date_3';
    if (group == GalleryGroup.family) return 'date_4';
    return 'date_1';
  }

  /// Map raw asset paths to display items.
  static List<GalleryImageItem> toItems(List<String> imagePaths) {
    return imagePaths.map((path) {
      final group = classifyGroup(path);
      return GalleryImageItem(
        path: path,
        group: group,
        location: locationFor(group),
        date: dateFor(group),
      );
    }).toList();
  }

  static Future<List<String>> loadImagePaths() => loadGalleryPhotoPaths();

  static Future<List<String>> _listAudioAssets() async {
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
    return audioFiles;
  }

  /// Default slideshow track: "Kiss the Rain — Yiruma", the canonical
  /// background music per PRODUCT.md. Falls back to the sorted-first
  /// bundled track when it is absent, or null when no audio is bundled.
  /// Returns paths with the `assets/` prefix stripped (legacy caller
  /// contract preserved).
  static const String defaultTrackHint = 'kiss the rain';

  static Future<String?> findFirstAudioAsset() async {
    try {
      final audioFiles = await _listAudioAssets().timeout(
        const Duration(seconds: 8),
      );
      if (audioFiles.isEmpty) return null;
      for (final file in audioFiles) {
        if (file.toLowerCase().contains(defaultTrackHint)) {
          return file.replaceFirst('assets/', '');
        }
      }
      return audioFiles.first.replaceFirst('assets/', '');
    } catch (e) {
      debugPrint('[GalleryRepo] no audio (fallback to null): $e');
      return null;
    }
  }

  static Future<List<String>> findAllAudioAssets() async {
    try {
      final audioFiles = await _listAudioAssets().timeout(
        const Duration(seconds: 8),
      );
      return audioFiles.map((key) => key.replaceFirst('assets/', '')).toList();
    } catch (e) {
      debugPrint('[GalleryRepo] audio list failed: $e');
      return [];
    }
  }
}
