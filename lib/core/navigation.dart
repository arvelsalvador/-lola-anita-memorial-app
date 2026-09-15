import 'package:flutter/material.dart';

/// Fade page route used for full-screen overlays.
///
/// [opaque] and [barrierColor] are exposed so viewers that need overlay
/// semantics (e.g. lightbox) don't have to hand-roll their own
/// `PageRouteBuilder`.
Route<T> fadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 260),
  Duration reverseDuration = const Duration(milliseconds: 200),
  bool opaque = true,
  Color? barrierColor,
}) {
  return PageRouteBuilder<T>(
    opaque: opaque,
    barrierColor: barrierColor,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
  );
}
