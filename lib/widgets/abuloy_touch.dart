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
/// Must be placed directly inside a [Stack], with [areaSize] matching that
/// stack's size (see [AbuloyTouchScope], or the Home shell which measures
/// its stack with a parent-side LayoutBuilder). The touch positions itself
/// relative to the stack.
class AbuloyTouch extends StatefulWidget {
  const AbuloyTouch({super.key, required this.areaSize});

  /// Size of the hosting stack. Drives the dock position and drag bounds.
  final Size areaSize;

  /// Hit area diameter (minimum 44x44 tap target). Public so tests and
  /// clamping share one source of truth.
  static const double size = 44;

  /// Diameter of the outer cream ring button.
  static const double buttonSize = 42;

  /// Diameter of the gold coin. The cream ring between coin and outer edge
  /// is ~3px thick ((42 - 36) / 2 = 3).
  static const double coinSize = 36;

  /// Edge margin kept when clamping the dragged position.
  static const double margin = 12;

  /// Legacy dock center fraction kept for backward compatibility with guide.
  static const double dockCenterFraction = 0.11;

  /// Top offset of the docked touch just below the top bar.
  static double dockTopFor(Size area, [double paddingTop = 0]) =>
      paddingTop + 53.0 + 8.0;

  @override
  State<AbuloyTouch> createState() => _AbuloyTouchState();
}

class _AbuloyTouchState extends State<AbuloyTouch> {
  /// Current position as a fraction (0..1) of the stack size. Null = docked
  /// default. Fractions keep the spot stable across screen size adjustments.
  Offset? _fraction;

  /// True while a drag is in flight.
  bool _dragging = false;

  void _openDialog(BuildContext context) {
    showAbuloyDialog(context);
  }

  Offset _defaultPosition(Size area, EdgeInsets padding) {
    // Dock top-right, right margin 12px, just below the top bar.
    return Offset(
      area.width - 12 - AbuloyTouch.size,
      padding.top + 53.0 + 8.0,
    );
  }

  Offset _toFraction(Offset px, Size area) => Offset(
    area.width <= 0 ? 0 : (px.dx / area.width).clamp(0.0, 1.0),
    area.height <= 0 ? 0 : (px.dy / area.height).clamp(0.0, 1.0),
  );

  Offset _toPixels(Offset f, Size area) =>
      Offset(f.dx * area.width, f.dy * area.height);

  Offset _clamp01(Offset f) =>
      Offset(f.dx.clamp(0.0, 1.0), f.dy.clamp(0.0, 1.0));

  Offset _clamp(Offset pos, Size area, EdgeInsets padding) {
    final maxX = (area.width - AbuloyTouch.size - 12.0).clamp(
      12.0,
      double.infinity,
    );
    final minY = padding.top + 53.0 + 8.0;
    final maxY =
        (area.height - padding.bottom - AbuloyTouch.size - AbuloyTouch.margin)
            .clamp(minY, double.infinity);
    return Offset(
      pos.dx.clamp(12.0, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final label = lang.t('donate_title');
    final area = widget.areaSize;
    final padding = MediaQuery.paddingOf(context);
    final frac = _fraction ?? _toFraction(_defaultPosition(area, padding), area);
    final pos = _clamp(_toPixels(frac, area), area, padding);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
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
            child: AbuloyTouchVisual(
              dragging: _dragging,
              onTap: () => _openDialog(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Abuloy coin itself, split out of [AbuloyTouch] so the first-run guide
/// can show the same artwork as a spotlit diagram without duplicating it.
class AbuloyTouchVisual extends StatelessWidget {
  const AbuloyTouchVisual({
    super.key,
    this.pulse = 0,
    this.dragging = false,
    this.onTap,
  });

  final double pulse;
  final bool dragging;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lift = dragging ? 1.0 : 0.0;
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
            // Outer cream ring with subtle static shadow
            Container(
              width: AbuloyTouch.buttonSize,
              height: AbuloyTouch.buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper.withValues(alpha: 0.95),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmDark.withValues(
                      alpha: 0.16 + 0.08 * lift,
                    ),
                    blurRadius: 10 + 4 * lift,
                    offset: Offset(0, 3 + 2 * lift),
                  ),
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // Inner gold coin with paper border and white glyph
            Container(
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
                border: Border.all(color: AppColors.paper, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withValues(alpha: 0.25),
                highlightColor: Colors.white.withValues(alpha: 0.12),
                onTap: onTap,
                child: const Center(
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps any page body so the assistive touch floats over it.
///
/// Use for pushed routes that live outside the Home shell's stack.
/// Measures the stack with a parent-side LayoutBuilder.
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
