import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:nita/core/constants/app_constants.dart';

/// The candle circle: a paused video of a candle being lit
/// (`assets/Video/candle.mp4`).
///
/// - Shows the first (unlit) frame paused when the page opens; nothing
///   autoplays.
/// - Tapping the circle plays the video once from start to finish and
///   fires [onLight]; when the end is reached it pauses there on the
///   lit frame instead of looping.
/// - [playSignal] lets the card-level button trigger the same one-shot
///   playback without double-lighting the counter.
/// - [onLight] fires the shared candle-light flow (counter, thank-you).
///   It still fires when the video can't load, so the gesture never
///   dies with the asset.
/// - While loading (or if the asset fails, e.g. in widget tests) a
///   quiet fallback medallion shows instead of an error.
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

  @override
  State<CandleVideo> createState() => _CandleVideoState();
}

class _CandleVideoState extends State<CandleVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _completed = false;
  int _lastSignal = 0;

  // TODO(temp-diagnostic): remove once the init failure is identified.
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(CandleVideo.assetPath);
    _controller.setLooping(false);
    _controller.addListener(_onTick);
    widget.playSignal.addListener(_onSignal);
    _lastSignal = widget.playSignal.value;
    _controller.initialize().then((_) {
      if (!mounted) return;
      // Rest on the first (unlit) frame — never autoplay.
      _controller.pause();
      setState(() => _ready = true);
    }).catchError((Object e) {
      debugPrint('[CandleVideo] initialize failed: $e');
      if (!mounted) return;
      setState(() {
        _failed = true;
        _errorMessage = '$e';
      });
    });
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
    _playVideo();
  }

  /// Pauses on the final frame instead of looping back to unlit.
  void _onTick() {
    if (!_ready || _failed || !mounted) return;
    final value = _controller.value;
    if (value.hasError) {
      // TODO(temp-diagnostic): remove once the init failure is identified.
      debugPrint('[CandleVideo] player error: ${value.errorDescription}');
      setState(() {
        _failed = true;
        _errorMessage = value.errorDescription ?? 'unknown player error';
      });
      return;
    }
    if (_completed || !value.isPlaying) return;
    final duration = value.duration;
    if (duration > Duration.zero && value.position >= duration) {
      _controller.pause();
      setState(() => _completed = true);
    }
  }

  /// Plays once from the start. Safe to call before init finishes or
  /// when the asset failed — it just no-ops the video part.
  Future<void> _playVideo() async {
    if (!_ready || _failed || !mounted) return;
    if (_controller.value.isPlaying) return;
    try {
      await _controller.seekTo(Duration.zero);
      if (!mounted) return;
      setState(() => _completed = false);
      await _controller.play();
    } catch (e) {
      // TODO(temp-diagnostic): remove once the init failure is identified.
      debugPrint('[CandleVideo] play failed: $e');
      if (!mounted) return;
      setState(() {
        _failed = true;
        _errorMessage = '$e';
      });
    }
  }

  void _handleTap() {
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
                  color: AppColors.white.withValues(alpha: 0.72),
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
                      ? VideoPlayer(_controller)
                      : _FallbackMedallion(
                          loading: !_failed,
                          // TODO(temp-diagnostic): remove once identified.
                          errorMessage: _errorMessage,
                        ),
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

  // TODO(temp-diagnostic): remove once the init failure is identified.
  final String errorMessage;

  const _FallbackMedallion({required this.loading, this.errorMessage = ''});

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
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 40,
                  color: AppColors.gold,
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
