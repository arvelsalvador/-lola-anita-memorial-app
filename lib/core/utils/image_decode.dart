import 'package:flutter/material.dart';

/// Decode-sizing helpers for [Image.asset] so small render sites never
/// decode full camera-resolution bitmaps.
///
/// Rule: `cacheWidth`/`cacheHeight` must be the logical render size
/// multiplied by the device pixel ratio (rounded) — a raw logical value
/// under-decodes on 2×/3× screens (blurry), while no bound at all wastes
/// memory on the bundled full-resolution photographs.
class ImageDecode {
  ImageDecode._();

  /// Bounded decode width for an image rendered [logicalWidth] wide.
  static int width(double logicalWidth, BuildContext context) =>
      (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();

  /// Bounded decode height for an image rendered [logicalHeight] tall.
  static int height(double logicalHeight, BuildContext context) =>
      (logicalHeight * MediaQuery.devicePixelRatioOf(context)).round();
}
