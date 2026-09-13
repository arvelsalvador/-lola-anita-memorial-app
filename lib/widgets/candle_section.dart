import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/candle_video.dart';

/// The "Sindihan ang kandila" card: a video of a candle being lit in
/// Nanay's memory, with a live count streamed from Firestore (falling back
/// to a local counter when Firebase is unavailable). Originally part of the
/// Tribute page, now hosted on the Pakikiramay (condolences) tab.
///
/// The circle shows the video's first (unlit) frame paused — nothing
/// autoplays. Tapping "light the candle" (on the video or the card
/// button) plays it once; it pauses on the final lit frame.
class CandleSection extends StatefulWidget {
  final TributeController tributeController;

  const CandleSection({super.key, required this.tributeController});

  @override
  State<CandleSection> createState() => _CandleSectionState();
}

class _CandleSectionState extends State<CandleSection> {
  /// Bumped every lighting so the video circle plays its one-shot
  /// playback for the full-width button as well as video taps.
  final ValueNotifier<int> _playSignal = ValueNotifier<int>(0);

  /// Whether the visitor opened condolences via the Condolences button.
  /// Gates both the message box and the closing quote — hidden by
  /// default, revealed only on tap.
  bool _condolencesOpen = false;

  @override
  void initState() {
    super.initState();
    widget.tributeController.addListener(_onChanged);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    widget.tributeController.removeListener(_onChanged);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _playSignal.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Message draft box state.
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  void _onMessageChanged() {
    if (mounted) setState(() {});
  }

  void _handleLightTap() {
    final controller = widget.tributeController;
    if (controller.lit || controller.loading) return;
    HapticFeedback.lightImpact();
    _playSignal.value++;
    controller.lightCandle();
  }

  /// Sends the visitor's words for Nanay. Tries to store them under the
  /// memorial's Firestore messages; offline or unconfigured backends
  /// still get the thank-you — the gesture never fails loudly.
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending || !mounted) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('memorial')
          .doc('anita_lumbao')
          .collection('messages')
          .add({
            'text': message,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Offline / unconfigured backend: the message still gets its thanks.
    }
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    _messageController.clear();
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warmDark,
        content: Text(lang.t('candle_message_thanks')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final controller = widget.tributeController;
    final lit = controller.lit;

    return Column(
      children: [
        CandleVideo(
          lit: lit,
          onLight: _handleLightTap,
          playSignal: _playSignal,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(lit),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lit ? lang.t('candle_lit') : lang.t('candle_light'),
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              // When lit, the title becomes a thank-you with a
              // subtitle for everyone condoling with Nanay Nita.
              if (lit) ...[
                const SizedBox(height: 4),
                Text(
                  lang.t('candle_thanks_subtitle'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: AppColors.warmMid,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: controller.candleStream,
          builder: (context, snapshot) {
            int count = controller.localCount;
            if (!snapshot.hasError &&
                snapshot.hasData &&
                snapshot.data!.exists) {
              final data = snapshot.data!.data();
              final remoteCount = data?['candleCount'];
              if (remoteCount is int) count = remoteCount;
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                // How many times visitors have lit the candle.
                Text(
                  lang.t('candle_lit_times', {'count': '$count'}),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.warmMid,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
        // The single light action: full-width dark pill. Hidden once
        // lit — the video then rests on its final frame.
        if (!lit) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: controller.loading ? null : _handleLightTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmDark,
                foregroundColor: const Color(0xFFFAF0E6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                elevation: 4,
                shadowColor: AppColors.warmDark.withValues(alpha: 0.35),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(lang.t('candle_light')),
            ),
          ),
        ],
        const SizedBox(height: 28),
        _RuledLine(text: lang.t('condolences_keepsake')),
        const SizedBox(height: 14),
        const _CandleRow(),
        const SizedBox(height: 20),
        // Condolences: a single button reveals the message box and the
        // closing quote below. Both stay hidden until tapped.
        if (_condolencesOpen) ...[
          _MessageBar(
            controller: _messageController,
            sending: _sending,
            onSend: _sendMessage,
          ),
          const SizedBox(height: 28),
          _ShortRuledLine(text: lang.t('condolences_each_flame')),
        ] else
          Center(
            child: SizedBox(
              width: 250,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _condolencesOpen = true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warmDeep,
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(
                  Icons.volunteer_activism_outlined,
                  size: 16,
                ),
                label: Text(lang.t('candle_condolences_button')),
              ),
            ),
          ),
      ],
    );
  }
}

/// Italic line of text held between two hairline rules, full width.
class _RuledLine extends StatelessWidget {
  final String text;
  const _RuledLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.warmMid,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

/// Shorter centered variant for the closing quote: stubby rules.
class _ShortRuledLine extends StatelessWidget {
  final String text;
  const _ShortRuledLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.warmMid,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

/// Ornamental row of seven small candles on a hairline, glowing gold
/// on the left and fading out to the right — every flame lit before
/// yours, trailing off.
class _CandleRow extends StatelessWidget {
  const _CandleRow();

  static const List<double> _alphas = [
    1.0,
    0.85,
    0.7,
    0.55,
    0.4,
    0.28,
    0.18,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < _alphas.length; i++)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream,
                  border: Border.all(
                    color: AppColors.gold.withValues(
                      alpha: 0.25 + 0.35 * _alphas[i],
                    ),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: const Color(0xFFB06A2B).withValues(
                    alpha: _alphas[i],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Inline words-for-Nanay bar pinned to the bottom of the lit-candle
/// card: textbox plus send. The parent owns the draft controller and
/// rebuilds this on every keystroke, so send enables only for non-empty
/// drafts.
class _MessageBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _MessageBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final canSend = controller.text.trim().isNotEmpty && !sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: lang.t('candle_message_hint'),
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: canSend ? onSend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.muted.withValues(
                  alpha: 0.3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              icon: sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 14),
              label: Text(
                lang.t('candle_message_send'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-painted candle flame: outer glow, terracotta-to-gold body, and a
/// cream core, grown upward from the wick by [unfurl] (0..1) and lit by
/// [glow] (0..1). Reusable set-piece for other memorial moments.
class CandleFlamePainter extends CustomPainter {
  final double unfurl;
  final double glow;

  const CandleFlamePainter({required this.unfurl, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final grow = unfurl.clamp(0.0, 1.0);
    if (grow <= 0.01) return;
    final cx = size.width / 2;
    final baseY = size.height - 4;
    final h = (size.height - 12) * grow;
    final w = 13.0 * (0.4 + 0.6 * grow);
    final top = baseY - 4 - h;

    // Wick.
    canvas.drawLine(
      Offset(cx, baseY + 2),
      Offset(cx, baseY - 3),
      Paint()
        ..color = AppColors.warmDeep
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    Path body() {
      return Path()
        ..moveTo(cx, top)
        ..cubicTo(
          cx + w,
          top + h * 0.30,
          cx + w * 0.95,
          top + h * 0.60,
          cx + w * 0.75,
          baseY - 4 - h * 0.12,
        )
        ..cubicTo(
          cx + w * 0.5,
          baseY - 4 + h * 0.02,
          cx - w * 0.5,
          baseY - 4 + h * 0.02,
          cx - w * 0.75,
          baseY - 4 - h * 0.12,
        )
        ..cubicTo(
          cx - w * 0.95,
          top + h * 0.60,
          cx - w,
          top + h * 0.30,
          cx,
          top,
        )
        ..close();
    }

    final alpha = grow.clamp(0.0, 1.0);

    // Outer glow halo.
    canvas.save();
    canvas.translate(cx, baseY - 4);
    canvas.scale(1.3);
    canvas.translate(-cx, -(baseY - 4));
    canvas.drawPath(
      body(),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.30 * glow * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    // Flame body, terracotta embers rising into gold.
    canvas.drawPath(
      body(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.terracotta.withValues(alpha: alpha),
            AppColors.gold.withValues(alpha: alpha),
          ],
        ).createShader(Rect.fromLTWH(cx - w, top, w * 2, h + 4)),
    );

    // Inner core, anchored at the base.
    canvas.save();
    canvas.translate(cx, baseY - 4);
    canvas.scale(0.45);
    canvas.translate(-cx, -(baseY - 4));
    canvas.drawPath(
      body(),
      Paint()..color = const Color(0xFFFFF6E3).withValues(alpha: 0.95 * alpha),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CandleFlamePainter oldDelegate) {
    return oldDelegate.unfurl != unfurl || oldDelegate.glow != glow;
  }
}

