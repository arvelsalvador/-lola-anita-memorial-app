import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Shared entrance timing. Keep page-specific entrance animations in sync
// with these values so every tab reveals at the same pace. Worst case is
// 400ms delay + 400ms animation = 800ms, comfortably before the guide's
// 1500ms auto-start.
const int kRevealInitialDelayMs = 75;
const int kRevealStaggerStepMs = 40;
const int kRevealMaxDelayMs = 400;
const Duration kRevealDuration = Duration(milliseconds: 400);

/// Reusable entrance animation widget matching the Tahanan (Home) page:
/// reveals [child] with a fade + directional slide the first time it
/// becomes visible in the viewport.
///
/// Features:
/// - Staggered delay via [index] (75ms + 40ms * index, capped at 400ms) or explicit [delay]
/// - Lateral slide (alternating 7% left/right, 3% down) or vertical [floatUp] (6% down)
/// - Single-play: does not replay when scrolling back up or on rebuilds/tab switches
/// - Keeps alive via [AutomaticKeepAliveClientMixin]
/// - [animate]: when false, immediately renders [child] without animation (for long list tail items)
/// - Pure Opacity and Transform transitions so layout geometry and guide highlights are unaffected
class RevealOnAppear extends StatefulWidget {
  final String? id;
  final int index;
  final Widget child;
  final bool floatUp;
  final Duration? delay;
  final Offset? beginOffset;
  final Duration duration;
  final bool animate;

  const RevealOnAppear({
    super.key,
    this.id,
    this.index = 0,
    required this.child,
    this.floatUp = false,
    this.delay,
    this.beginOffset,
    this.duration = kRevealDuration,
    this.animate = true,
  });

  @override
  State<RevealOnAppear> createState() => _RevealOnAppearState();
}

class _RevealOnAppearState extends State<RevealOnAppear>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _revealed = false;
  Timer? _delayTimer;
  Timer? _safetyTimer;

  @override
  bool get wantKeepAlive => true;

  Offset get _beginOffset {
    if (widget.floatUp) return const Offset(0, 0.06);
    return Offset(widget.index.isEven ? -0.07 : 0.07, 0.03);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.beginOffset ?? _beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (!widget.animate) {
      _revealed = true;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_revealed || info.visibleFraction <= 0.15) return;
    _revealed = true;

    final delay =
        widget.delay ??
        Duration(
          milliseconds: math.min(
            kRevealInitialDelayMs + kRevealStaggerStepMs * widget.index,
            kRevealMaxDelayMs,
          ),
        );

    _delayTimer = Timer(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    // Safety fallback: ensure widget is 100% visible even if animation
    // was interrupted or delayed by fast navigation/tab switches.
    _safetyTimer = Timer(
      delay + widget.duration + const Duration(milliseconds: 200),
      () {
        if (mounted && !_controller.isCompleted) {
          _controller.value = 1.0;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.animate) {
      return widget.child;
    }

    final keyString =
        widget.id ??
        'reveal-${widget.index}-${widget.child.key ?? widget.child.hashCode}';

    return VisibilityDetector(
      key: Key('scroll-reveal-$keyString'),
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}
