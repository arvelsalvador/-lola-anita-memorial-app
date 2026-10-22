import 'package:flutter/material.dart';

import 'package:nita/views/guide/guide_content.dart';

/// Decodes every bundled guide pose into Flutter's image cache.
///
/// `Image.asset` only starts reading and decoding after it is built, so the
/// first frame of the guide-choice dialog can paint with an empty mascot slot.
/// Warming the same `AssetImage` keys here lets the widgets paint the artwork
/// synchronously on their first frame.
Future<void> precacheGuideArt(BuildContext context) async {
  try {
    await Future.wait([
      for (final art in GuideArt.values)
        precacheImage(AssetImage(art.asset), context),
    ]);
  } catch (e) {
    // Missing artwork must never block the visitor from entering the guide.
    debugPrint('Guide art precache skipped: $e');
  }
}

/// Fades artwork in only when it actually had to wait for a decode.
///
/// When the asset is already cached (the normal path after
/// [precacheGuideArt]), the image paints immediately with no fade at all.
Widget guideArtFrameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOut,
    child: child,
  );
}
