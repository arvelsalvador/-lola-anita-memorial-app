import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:nita/core/constants/app_constants.dart';

/// The candle circle: a video of a candle being lit
/// (`assets/Video/candle.mp4`) resting on its first (unlit) frame.
///
/// - Holds the first (unlit) frame when the page opens; nothing
///   autoplays. That frame is *primed* after initialization (one muted
///   playback tick, then pause + seek back to zero) because the desktop
///   backend (fvp/MDK) only feeds pixels to the texture while the
///   player is actually rendering — a merely paused controller leaves
///   the circle blank.
/// - Tapping the circle plays the video once from start to finish and
///   fires [onLight]; when the end is reached it pauses there on the
///   lit frame instead of looping.
/// - A still photo of the same candle sits *under* the video, so when the
///   backend has no frame to publish (a transparent/empty texture — the
///   blank state this circle opened in on Windows) the circle still
///   shows a candle instead of a hole.
/// - [playSignal] lets the card-level button trigger the same one-shot
///   playback without double-lighting the counter.
/// - [onLight] fires the shared candle-light flow (counter, thank-you).
///   It still fires when the video can't load, so the gesture never
///   dies with the asset.
/// - While loading (or if the asset fails, e.g. in widget tests) the
///   medallion shows instead of an error.
///
/// Owns its [VideoPlayerController]: created in [initState], disposed
/// in [dispose].
class CandleVideo extends StatefulWidget {
  final bool lit;
  final VoidCallback onLight;
  final ValueListenable<int> playSignal;

  const CandleVideo({
    super.key,
    required this.lit,
    required this.onLight,
    required this.playSignal,
  });

  static const String assetPath = 'assets/Video/candle.mp4';

  /// Still candle (first-frame stand-in) drawn under the video.
  static const String stillPath = 'assets/images/Editing images/candle.png';

  @override
  State<CandleVideo> createState() => _CandleVideoState();
}

class _CandleVideoState extends State<CandleVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _completed = false;
  int _lastSignal = 0;

  /// True while [_primeFirstFrame] is holding the first frame. A visitor
  /// tap clears it, so the prime can never pause playback the visitor
  /// started in the same breath.
  bool _priming = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(CandleVideo.assetPath);
    // setLooping is a Future that can fail on platforms without an
    // implementation — observe (and swallow) it instead of leaving an
    // unhandled async error.
    _controller.setLooping(false).catchError((_) {});
    _controller.addListener(_onTick);
    widget.playSignal.addListener(_onSignal);
    _lastSignal = widget.playSignal.value;
    _controller
        .initialize()
        .timeout(const Duration(seconds: 10))
        .then((_) async {
          if (!mounted) return;
          // Rest on the first (unlit) frame — never autoplay.
          _controller.pause();
          setState(() => _ready = true);
          // …then make sure that frame actually reached the texture.
          await _primeFirstFrame();
        })
        .catchError((Object e) {
          debugPrint('[CandleVideo] initialize failed: $e');
          if (!mounted) return;
          setState(() => _failed = true);
        });
  }

  /// Renders and holds the first (unlit) frame.
  ///
  /// On Windows/Linux the `video_player` implementation is fvp/MDK,
  /// which only feeds pixels to the Flutter texture from its render
  /// callback — i.e. while the player is rendering. A controller that is
  /// merely paused after `initialize()` therefore leaves the texture
  /// empty and the circle opens blank. One muted playback tick publishes
  /// the frame; pausing and seeking back to zero then holds it exactly
  /// as designed.
  Future<void> _primeFirstFrame() async {
    if (!mounted || _failed || _completed) return;
    final volume = _controller.value.volume;
    _priming = true;
    try {
      // Muted so priming can never blip the video's audio track.
      await _controller.setVolume(0).timeout(const Duration(seconds: 2));
      await _controller.play().timeout(const Duration(seconds: 2));
      // ~3 frames at the video's 24 fps: enough to render and publish
      // the first frame, with no visible movement of the unlit candle.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_priming) return;
      await _controller.pause().timeout(const Duration(seconds: 2));
      // Land exactly on the first (unlit) frame.
      await _controller
          .seekTo(Duration.zero)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      // Priming is polish: the tap-to-light flow still works without it.
      debugPrint('[CandleVideo] first-frame prime failed: $e');
    } finally {
      _priming = false;
      if (mounted) {
        try {
          await _controller
              .setVolume(volume)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          // Volume restore is best-effort — never surface it to a visitor.
        }
      }
    }
  }

  @override
  void dispose() {
    widget.playSignal.removeListener(_onSignal);
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onSignal() {
    if (widget.playSignal.value == _lastSignal) return;
    _lastSignal = widget.playSignal.value;
    // The visitor is driving now — never let the prime pause their play.
    _priming = false;
    _playVideo();
  }

  /// Pauses on the final frame instead of looping back to unlit.
  void _onTick() {
    if (!_ready || _failed || !mounted) return;
    final value = _controller.value;
    if (value.hasError) {
      debugPrint('[CandleVideo] player error: ${value.errorDescription}');
      setState(() => _failed = true);
      return;
    }
    if (_completed || !value.isPlaying) return;
    final duration = value.duration;
    // Some platforms clamp position ~100-200ms short of duration (or stop
    // the playing flag first), so treat near-the-end as the end instead
    // of requiring exact equality — otherwise the video sits on a
    // near-last frame and _completed never flips.
    if (duration > Duration.zero &&
        value.position >= duration - const Duration(milliseconds: 300)) {
      _controller.pause();
      if (mounted) setState(() => _completed = true);
    }
  }

  /// Plays once from the start. Safe to call before init finishes or
  /// when the asset failed — it just no-ops the video part.
  Future<void> _playVideo() async {
    if (!_ready || _failed || !mounted) return;
    if (_controller.value.isPlaying) return;
    try {
      await _controller
          .seekTo(Duration.zero)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _completed = false);
      await _controller.play().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[CandleVideo] play failed: $e');
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _handleTap() {
    _priming = false; // the visitor is driving now
    _playVideo();
    widget.onLight();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 224,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Faint outer halo ring.
          Container(
            width: 224,
            height: 224,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
          ),
          // Inner halo ring hugging the circle.
          Container(
            width: 208,
            height: 208,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(
                  alpha: widget.lit || _completed ? 0.45 : 0.3,
                ),
                width: 1,
              ),
            ),
          ),
          // The circle itself: video once ready, fallback before that.
          // Tapping it lights the candle.
          Positioned(
            top: 12,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper.withValues(alpha: 0.72),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(
                        alpha: widget.lit || _completed ? 0.4 : 0.15,
                      ),
                      blurRadius: widget.lit || _completed ? 32 : 14,
                      spreadRadius: widget.lit || _completed ? 2 : 0,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _ready && !_failed
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Still candle under the video: an empty or
                            // transparent texture reveals it, a painted
                            // video frame covers it.
                            Image.asset(
                              CandleVideo.stillPath,
                              fit: BoxFit.cover,
                              // 1920px source in a 200px circle: decode
                              // small so the poster stays cheap.
                              cacheWidth: 400,
                              filterQuality: FilterQuality.medium,
                            ),
                            VideoPlayer(_controller),
                          ],
                        )
                      : _FallbackMedallion(loading: !_failed),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet stand-in while the video loads or when the asset is missing:
/// a candle glyph (or a spinner while still trying).
class _FallbackMedallion extends StatelessWidget {
  final bool loading;

  const _FallbackMedallion({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: AppColors.cream,
      padding: const EdgeInsets.all(12),
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.rose,
              ),
            )
          : const Icon(
              Icons.local_fire_department_rounded,
              size: 40,
              color: AppColors.gold,
            ),
    );
  }
}
