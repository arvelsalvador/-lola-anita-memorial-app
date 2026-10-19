import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/donation_section.dart';
import 'package:nita/widgets/ornamental_card.dart';

/// Floating assistive touch for Abuloy: one quiet entry point visible on
/// every main tab. Tapping opens the donation dialog, so the gift stays
/// reachable no matter how long the forum feed grows.
///
/// The touch can be dragged anywhere on screen (like iOS AssistiveTouch)
/// and stays where the visitor leaves it while the app is open. Position
/// is clamped to the visible area so it can never be lost off-screen.
///
/// A slow breathing halo makes it noticeable at first glance; the pulse
/// freezes the moment the dialog is first opened, so it quiets down once
/// discovered.
///
/// Must be placed directly inside a [Stack], with [areaSize] matching that
/// stack's size (see [AbuloyTouchScope], or the Home shell which measures
/// its stack with a parent-side LayoutBuilder). The touch positions itself
/// relative to the stack — screen size would be wrong wherever the stack
/// doesn't fill the screen (e.g. under the expanded memorial hero).
class AbuloyTouch extends StatefulWidget {
  const AbuloyTouch({super.key, required this.areaSize});

  /// Size of the hosting stack. Drives the dock position and drag bounds.
  final Size areaSize;

  /// Diameter of the touch (outer halo at rest). Public so tests and
  /// clamping share one source of truth.
  static const double size = 60;

  /// Diameter of the gold coin. The white ring between coin and halo comes
  /// from the coin's paper border.
  static const double coinSize = 45;

  /// Edge margin kept when clamping the dragged position.
  static const double margin = 8;

  @override
  State<AbuloyTouch> createState() => _AbuloyTouchState();
}

class _AbuloyTouchState extends State<AbuloyTouch>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver // pauses the breathing pulse in the background
    {
  /// Current position as a fraction (0..1) of the stack size. Null = docked
  /// default. Fractions keep the spot (e.g. the middle) stable when moving
  /// between tabs whose stacks have different sizes — absolute pixels would
  /// land somewhere else after clamping (seen on Tahanan vs Galeri).
  Offset? _fraction;

  /// True while a drag is in flight — slightly deepens the shadow so the
  /// visitor feels the lift.
  bool _dragging = false;

  /// Slow breathing pulse for the halo (0..1, eased). Runs until the dialog
  /// is first opened, then freezes — the last frame simply becomes a static
  /// halo, so there is never a visible pop.
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  /// Whether [_pulse] is currently repeating; mirrors state so lifecycle
  /// callbacks and [_openDialog] never fight over the controller.
  bool _pulseRunning = true;

  /// True once the dialog was first opened — the pulse is then permanently
  /// frozen and must not restart on app resume.
  bool _pulseFrozen = false;

  @override
  void initState() {
    super.initState();
    // The infinite pulse would keep ticking while backgrounded; observe
    // the app lifecycle and pause it off-screen.
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pulseRunning || _pulseFrozen) return;
      _pulseRunning = true;
      _pulse.repeat(reverse: true);
    } else {
      if (!_pulseRunning) return;
      _pulseRunning = false;
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  /// Freezes the pulse on first open; the frozen frame stays as a static
  /// halo. Idempotent — later taps just open the dialog.
  void _openDialog(BuildContext context) {
    if (!_pulseFrozen) {
      _pulseFrozen = true;
      _pulseRunning = false;
      _pulse.stop();
    }
    showAbuloyDialog(context);
  }

  Offset _defaultPosition(Size area, EdgeInsets padding) {
    // Short strip (e.g. under the expanded memorial hero): dock at the top
    // so the touch never covers the bottom nav's tap targets. Roomy area:
    // dock bottom-right, just above the nav.
    final top = area.height <= 220
        ? AbuloyTouch.margin
        : area.height - padding.bottom - 104 - AbuloyTouch.size;
    return Offset(area.width - 20 - AbuloyTouch.size, top);
  }

  Offset _toFraction(Offset px, Size area) => Offset(
    area.width <= 0 ? 0 : (px.dx / area.width).clamp(0.0, 1.0),
    area.height <= 0 ? 0 : (px.dy / area.height).clamp(0.0, 1.0),
  );

  Offset _toPixels(Offset f, Size area) =>
      Offset(f.dx * area.width, f.dy * area.height);

  /// Keeps a fraction inside the 0..1 square.
  Offset _clamp01(Offset f) =>
      Offset(f.dx.clamp(0.0, 1.0), f.dy.clamp(0.0, 1.0));

  Offset _clamp(Offset pos, Size area, EdgeInsets padding) {
    final maxX = (area.width - AbuloyTouch.size - AbuloyTouch.margin).clamp(
      AbuloyTouch.margin,
      double.infinity,
    );
    final minY = AbuloyTouch.margin + padding.top;
    final maxY =
        (area.height - padding.bottom - AbuloyTouch.size - AbuloyTouch.margin)
            .clamp(minY, double.infinity);
    return Offset(
      pos.dx.clamp(AbuloyTouch.margin, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final label = lang.t('donate_title');
    // NOTE: Positioned must be returned directly (no LayoutBuilder between
    // it and the Stack) or Flutter throws a ParentDataWidget error. The
    // stack's size therefore arrives via [AbuloyTouch.areaSize], measured
    // by a parent-side LayoutBuilder — MediaQuery screen size would be
    // wrong wherever the stack doesn't fill the screen.
    final area = widget.areaSize;
    final padding = MediaQuery.paddingOf(context);
    final frac =
        _fraction ?? _toFraction(_defaultPosition(area, padding), area);
    final pos = _clamp(_toPixels(frac, area), area, padding);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        // Accumulate onto live [_fraction] (updated synchronously), NOT the
        // build-captured point: several pointer events can arrive between
        // frames, and basing each on the stale build point would drop
        // movement and make the drag lag behind the finger.
        onPanUpdate: (details) {
          // Guard the sizes the same way [_toFraction] does: a degenerate
          // (zero-sized) area would send delta / 0 to Infinity, and after
          // clamping that teleports the touch to a corner instead of
          // dragging it.
          if (area.width <= 0 || area.height <= 0) return;
          setState(() {
            final base = _fraction ?? _toFraction(pos, area);
            _fraction = _clamp01(
              Offset(
                base.dx + details.delta.dx / area.width,
                base.dy + details.delta.dy / area.height,
              ),
            );
          });
        },
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        child: Semantics(
          button: true,
          label: label,
          child: Tooltip(
            message: label,
            // Only the visuals rebuild per pulse tick — position and
            // gestures stay untouched.
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) {
                // 0 = rest. The value freezes when the pulse stops (first
                // open or dispose), so the halo simply goes still.
                final p = _pulseAnim.value;
                final lift = _dragging ? 1.0 : 0.0;
                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: SizedBox(
                    width: AbuloyTouch.size,
                    height: AbuloyTouch.size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Clean attention ring: noticeable while browsing,
                        // but airy enough not to feel like an alert badge.
                        Transform.scale(
                          scale: 0.88 + 0.22 * p,
                          child: Opacity(
                            opacity: 0.34 - 0.22 * p,
                            child: Container(
                              width: AbuloyTouch.size,
                              height: AbuloyTouch.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.rose,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.14,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: AbuloyTouch.coinSize + 8,
                          height: AbuloyTouch.coinSize + 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.paper.withValues(alpha: 0.92),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.32),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmDark.withValues(
                                  alpha: 0.14 + 0.08 * lift,
                                ),
                                blurRadius: 18 + 8 * lift,
                                offset: Offset(0, 7 + 3 * lift),
                              ),
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        // Warm coin with a paper ring and white glyph.
                        Transform.scale(
                          scale: 1.0 + 0.035 * p + 0.03 * lift,
                          child: Container(
                            width: AbuloyTouch.coinSize,
                            height: AbuloyTouch.coinSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.glowGold,
                                  AppColors.gold,
                                  AppColors.copper,
                                ],
                                stops: [0.0, 0.58, 1.0],
                              ),
                              border: Border.all(
                                color: AppColors.paper,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  blurRadius: 6,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: Colors.white.withValues(alpha: 0.25),
                              highlightColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                              onTap: () => _openDialog(context),
                              child: const Center(
                                child: Icon(
                                  Icons.volunteer_activism_outlined,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps any page body so the assistive touch floats over it.

/// Use for pushed routes (Settings, detail pages) that live outside the
/// Home shell's stack — the five main tabs already carry [AbuloyTouch].
/// Measures the stack with a parent-side LayoutBuilder (legal position —
/// a LayoutBuilder *between* [AbuloyTouch] and its Stack would crash).
class AbuloyTouchScope extends StatelessWidget {
  final Widget child;
  const AbuloyTouchScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          child,
          AbuloyTouch(
            areaSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        ],
      ),
    );
  }
}

/// Opens the Abuloy dialog: the same [DonationCardBody] as the Pakikiramay
/// page section, centered and width-capped so it reads well on phones,
/// tablets, and desktop web alike.
Future<void> showAbuloyDialog(BuildContext context) {
  try {
    HapticFeedback.lightImpact().catchError((_) {});
  } catch (_) {
    // Haptics unavailable on desktop — the dialog still opens.
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final lang = dialogContext.watch<LanguageProvider>();
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: OrnamentalCard(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 20,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lang.t('donate_title'),
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 22,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: lang.t('donate_close'),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: AppColors.warmMid,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    Text(
                      lang.t('donate_subtitle'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.warmMid,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const DonationCardBody(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
