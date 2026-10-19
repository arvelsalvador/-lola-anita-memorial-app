import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:nita/core/utils/motion.dart';

/// Full-bleed, muted, looping video ground for the splash.
///
/// Deliberately defensive — this is the app's first real video playback path,
/// so every platform call is guarded. If the decoder is missing (widget
/// tests, desktop without a video backend) or the clip is unusable, the
/// widget renders nothing and the caller's painted night-vigil backdrop stays
/// visible. Nothing here can block, delay, or crash startup.
///
/// Callers place this directly above their painted fallback and pass
/// [onReady] to fade in a legibility scrim with the video, so the fallback
/// look is untouched while the video loads or is unavailable.
class SplashVideoBackdrop extends StatefulWidget {
  const SplashVideoBackdrop({super.key, required this.asset, this.onReady});

  /// Asset path of the splash clip.
  final String asset;

  /// Called once, when the clip is initialised and its first frame is ready
  /// to paint.
  final VoidCallback? onReady;

  @override
  State<SplashVideoBackdrop> createState() => _SplashVideoBackdropState();
}

class _SplashVideoBackdropState extends State<SplashVideoBackdrop>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Late init: the memorial content paints on the first frame and the
    // decoder never delays startup.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (!_ready || controller == null) return;
    // Reduced motion rests on the first frame — never resume it.
    if (animationsDisabled()) return;
    try {
      if (state == AppLifecycleState.resumed) {
        controller.play();
      } else {
        controller.pause();
      }
    } catch (_) {
      // Platform gone (e.g. surface destroyed) — nothing to do.
    }
  }

  Future<void> _start() async {
    if (_disposed) return;
    try {
      final controller = VideoPlayerController.asset(widget.asset);
      _controller = controller;
      // Timeout so a wedged native decoder can't hold the controller open
      // forever; the painted fallback simply stays on screen.
      await controller.initialize().timeout(const Duration(seconds: 8));
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (_disposed) return;
      // Reduced motion: hold the first frame as a still.
      if (animationsDisabled()) {
        await controller.seekTo(Duration.zero);
      } else {
        await controller.play();
      }
      if (_disposed) return;
      final size = controller.value.size;
      if (size.width <= 0 || size.height <= 0) {
        // No measurable frame — treat as unusable and fall back.
        _disposeController();
        return;
      }
      setState(() => _ready = true);
      widget.onReady?.call();
    } catch (error) {
      // No platform implementation (widget tests, desktop without fvp), a
      // corrupt clip, or a slow decoder: fail quietly, leave the fallback.
      debugPrint('SplashVideoBackdrop: video unavailable — $error');
      _disposeController();
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      controller.dispose();
    } catch (_) {
      // An uninitialised controller can throw from a platform with no video
      // backend; nothing to clean up in that case.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) return const SizedBox.shrink();

    final size = controller.value.size;
    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
