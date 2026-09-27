part of 'home_page.dart';

/// Wraps a tappable card/button with a subtle press-down scale, so taps
/// feel responsive beyond the bare ink ripple. Keep durations short (≤150ms)
/// so it reads as instant feedback, not a distinct animation.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const _Pressable({
    required this.child,
    required this.borderRadius,
    this.onTap,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Reveals [child] with a fade + directional slide the first time it
/// becomes meaningfully visible while scrolling — not on mount. Content
/// below the fold starts fully hidden until the user actually scrolls it
/// into view, then it settles in once and stays.
class _ScrollReveal extends StatefulWidget {
  final String id;
  final int index;
  final Widget child;
  final bool floatUp;

  const _ScrollReveal({
    required this.id,
    required this.index,
    required this.child,
    this.floatUp = false,
  });

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: _beginOffset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  bool _revealed = false;
  Timer? _delayTimer;
  @override
  bool get wantKeepAlive => true;

  Offset get _beginOffset {
    if (widget.floatUp) return const Offset(0, 0.08);
    return Offset(widget.index.isEven ? -0.10 : 0.10, 0.04);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_revealed || info.visibleFraction <= 0.15) return;
    _revealed = true;
    _delayTimer = Timer(
      Duration(milliseconds: 150 + 80 * (widget.index % 4)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return VisibilityDetector(
      key: Key('scroll-reveal-${widget.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}

/// Fades and slides a list item in on first build, offset by [index] so a
/// list of cards animates in as a gentle cascade rather than popping in all
/// at once. Cheap — no AnimationController needed.
class _StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A slow, quiet warmth behind the portrait frame — a soft radial glow that
/// breathes in and out over several seconds. Meant to feel like a candle's
/// light, not a UI effect; kept subtle on purpose.
class _GlowPulse extends StatefulWidget {
  final double size;
  const _GlowPulse({required this.size});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  // Static mid-glow when the OS requests reduced motion.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (animationsDisabled()) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.paleGold.withValues(alpha: 0.10 + 0.16 * t),
                AppColors.paleGold.withValues(alpha: 0),
              ],
            ),
          ),
        );
      },
    );
  }
}


