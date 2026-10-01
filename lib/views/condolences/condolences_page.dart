import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/candle_section.dart';

/// The Pakikiramay (condolences) tab: the visitor lights a virtual candle
/// in Nanay's memory. The [CandleSection] lives here and the tab owns it
/// going forward.
class CondolencesPage extends StatelessWidget {
  final ScrollController? controller;

  /// Candle controller, owned by the home shell (composition root)
  /// and injected here — the view never constructs or owns the controller.
  final CondolencesController condolencesController;

  const CondolencesPage({
    super.key,
    this.controller,
    required this.condolencesController,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      controller: controller,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _PakikiramayHeader(
              title: lang.t('nav_condolences'),
              subtitle: lang.t('condolences_subtitle'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              CandleSection(condolencesController: condolencesController),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Pakikiramay title matching the reference image: large Lora bold
/// dark-brown title, warm subtitle, and a line–sprig–line gold divider.
/// Local to this tab so Words/Gallery headers stay untouched.
class _PakikiramayHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PakikiramayHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.warmMid,
          ),
        ),
        const SizedBox(height: 10),
        const _LeafDivider(),
      ],
    );
  }
}

/// Line–sprig–line divider: two hairlines with a tiny three-leaf
/// gold sprig in the middle, like the reference image.
class _LeafDivider extends StatelessWidget {
  const _LeafDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 10),
        CustomPaint(
          size: const Size(26, 16),
          painter: _SprigPainter(),
        ),
        const SizedBox(width: 10),
        Container(
          width: 72,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.45),
        ),
      ],
    );
  }
}

class _SprigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold;
    final cx = size.width / 2;
    final baseY = size.height - 1;
    // Stem.
    canvas.drawLine(
      Offset(cx, baseY),
      Offset(cx, 3),
      paint..strokeWidth = 1.2,
    );
    // Three leaves: top + left + right.
    _leaf(canvas, Offset(cx, 5), 0, paint);
    _leaf(canvas, Offset(cx - 1, 9), -0.7, paint);
    _leaf(canvas, Offset(cx + 1, 9), 0.7, paint);
  }

  void _leaf(Canvas canvas, Offset at, double angle, Paint paint) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      const Rect.fromLTWH(-2.2, -4.5, 4.4, 9),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
