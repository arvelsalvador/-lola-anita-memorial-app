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
/// becomes meaningfully visible while scrolling — delegates to the shared
/// [RevealOnAppear] widget.
class _ScrollReveal extends StatelessWidget {
  final String id;
  final int index;
  final Widget child;
  final bool floatUp;

  const _ScrollReveal({
    super.key,
    required this.id,
    required this.index,
    required this.child,
    this.floatUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return RevealOnAppear(id: id, index: index, floatUp: floatUp, child: child);
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
      duration: Duration(milliseconds: math.min(240 + index * 35, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
