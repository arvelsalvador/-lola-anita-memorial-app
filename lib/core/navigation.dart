import 'package:flutter/material.dart';

/// Fade page route used for full-screen overlays.
Route<T> fadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 260),
}) {
  return PageRouteBuilder<T>(
    opaque: true,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: duration,
  );
}
