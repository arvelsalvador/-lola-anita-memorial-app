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
/// Deliberately subdued (small paper circle, gold hairline, no idle
/// animation) to respect the memorial's quiet tone — an aid, not an
/// advertisement. Must be placed directly inside a [Stack].
class AbuloyTouch extends StatefulWidget {
  const AbuloyTouch({super.key});

  /// Diameter of the touch circle. Public so tests can assert clamping.
  static const double size = 52;

  /// Edge margin kept when clamping the dragged position.
  static const double margin = 8;

  @override
  State<AbuloyTouch> createState() => _AbuloyTouchState();
}

class _AbuloyTouchState extends State<AbuloyTouch> {
  /// Current top-left position. Null = docked default (bottom-right,
  /// just above the bottom nav).
  Offset? _position;

  /// True while a drag is in flight — slightly deepens the shadow so the
  /// visitor feels the lift.
  bool _dragging = false;

  Offset _defaultPosition(Size screen, EdgeInsets padding) => Offset(
    screen.width - 20 - AbuloyTouch.size,
    screen.height - padding.bottom - 104 - AbuloyTouch.size,
  );

  Offset _clamp(Offset pos, Size screen, EdgeInsets padding) {
    final maxX = (screen.width - AbuloyTouch.size - AbuloyTouch.margin).clamp(
      AbuloyTouch.margin,
      double.infinity,
    );
    final minY = AbuloyTouch.margin + padding.top;
    final maxY =
        (screen.height - padding.bottom - AbuloyTouch.size - AbuloyTouch.margin)
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
    // it and the Stack) or Flutter throws a ParentDataWidget error, so the
    // screen size comes from MediaQuery instead of layout constraints.
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final pos = _clamp(
      _position ?? _defaultPosition(screen, padding),
      screen,
      padding,
    );
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) => setState(() {
          _position = _clamp(pos + details.delta, screen, padding);
        }),
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        child: Semantics(
          button: true,
          label: label,
          child: Tooltip(
            message: label,
            child: Material(
              color: AppColors.paper,
              shape: const CircleBorder(),
              elevation: 0,
              child: Container(
                width: AbuloyTouch.size,
                height: AbuloyTouch.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmDark.withValues(
                        alpha: _dragging ? 0.2 : 0.12,
                      ),
                      blurRadius: _dragging ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showAbuloyDialog(context),
                  child: const Center(
                    child: Icon(
                      Icons.volunteer_activism_outlined,
                      size: 26,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
                        Expanded(
                          child: Text(
                            lang.t('donate_title'),
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 20,
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
                        fontFamily: 'Lora',
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
