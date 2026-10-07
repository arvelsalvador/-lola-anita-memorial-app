import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/condolences/condolence_repository.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/condolences/candle_video.dart';

/// The "Sindihan ang kandila" card: a video of a candle being lit in
/// Nanay's memory, with a local session counter (Firebase paused).
/// Hosted on the Pakikiramay (condolences) tab; quotes live on Words.
///
/// The circle shows the video's first (unlit) frame paused — nothing
/// autoplays. Tapping "light the candle" (on the video or the card
/// button) plays it once; it pauses on the final lit frame.
class CandleSection extends StatefulWidget {
  final CondolencesController condolencesController;

  const CandleSection({super.key, required this.condolencesController});

  @override
  State<CandleSection> createState() => _CandleSectionState();
}

/// Pangalan validator: blocks empty, digits/symbols, vowel-less
/// strings, and keyboard-mash gibberish — so `lyca13` fails while
/// `Marc`, `Princess`, `Maria Clara`, `Anne-Marie`, `D'Angelo`, `Sy`
/// pass. Spam like `awdasdawsdawawd` / `asdfghjkl` is rejected via
/// lightweight heuristics (no backend dictionary needed).
String? validateCandleName(String input) {
  final name = input.trim();
  if (name.isEmpty) return 'candle_name_required';
  if (name.length > 50) return 'candle_name_invalid';
  // Letters (any language) + space + hyphen + apostrophes only.
  if (!RegExp(r"^[\p{L} '\-’']+$", unicode: true).hasMatch(name)) {
    return 'candle_name_invalid';
  }
  final letters = name.replaceAll(RegExp(r"[ '\-’']"), '');
  if (letters.length < 2) return 'candle_name_invalid';
  // At least one vowel-like character (y counts, for names like Sy).
  const vowelPattern =
      r'[aeiouyAEIOUYàáâãäåèéêëìíîïòóôõöùúûüýÿÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝ]';
  if (!RegExp(vowelPattern).hasMatch(name)) {
    return 'candle_name_invalid';
  }
  // Every word/token must contain a vowel (blocks `wxxz`, `qrst`).
  // Single-letter tokens are initials (`D'Angelo`, `O'Neil`) — skip them.
  for (final part in name.split(RegExp(r"[ '\-’']+")).where((p) => p.isNotEmpty)) {
    if (part.length <= 1) continue;
    if (!RegExp(vowelPattern).hasMatch(part)) {
      return 'candle_name_invalid';
    }
  }
  final compact = letters.toLowerCase();
  // Same character 3+ times in a row (`aaaa`, `www`).
  if (RegExp(r'(.)\1\1').hasMatch(compact)) {
    return 'candle_name_invalid';
  }
  // 4+ consonants in a row (`sdfghjkl`, `wdsdws`). y counts as vowel.
  if (RegExp(
    r'[^aeiouyàáâãäåèéêëìíîïòóôõöùúûüýÿ]{4,}',
  ).hasMatch(compact)) {
    return 'candle_name_invalid';
  }
  // Low letter diversity for longer input: keyboard mash reuses a few
  // keys (`awdasdawsdawawd` = 4 unique / 14 ≈ 0.29). Real names are
  // more varied. Only applied at length 6+ so `Anna` (0.5) still passes.
  if (compact.length >= 6) {
    final uniqueCount = compact.split('').toSet().length;
    if (uniqueCount / compact.length < 0.35) {
      return 'candle_name_invalid';
    }
  }
  // Repeated 3-letter chunk (`awd…awd`) — rare in real names.
  for (var i = 0; i <= compact.length - 3; i++) {
    final tri = compact.substring(i, i + 3);
    if (compact.indexOf(tri, i + 1) != -1) {
      return 'candle_name_invalid';
    }
  }
  return null;
}

class _CandleSectionState extends State<CandleSection> {
  final VisitorRepository _visitorRepo = const VisitorRepository();
  final CondolenceRepository _condolenceRepo = const CondolenceRepository();

  /// Full name from the splash gate (saved to DB).
  /// Empty = anonymous / unreadable.
  String _visitorFull = '';

  @override
  void initState() {
    super.initState();
    widget.condolencesController.addListener(_onChanged);
    _messageController.addListener(_onMessageChanged);
    _loadVisitor();
    _loadRemote();
  }

  /// Shared count + names-only list from the `visitors` table
  /// (who entered the app). Selects names only — addresses stay private.
  /// A null snapshot means offline: the list hides and an offline note
  /// shows instead. Never throws. [afterSave] clears the pending
  /// own-candle overlay because the server snapshot now includes us.
  Future<void> _loadRemote({bool afterSave = false}) async {
    final controller = widget.condolencesController;
    controller.setListLoading(true);
    final results = await Future.wait([
      _visitorRepo.fetchVisitorCount(),
      _visitorRepo.fetchVisitorNames(),
    ]);
    if (!mounted) return;
    controller.applyRemote(
      count: results[0] as int?,
      names: (results[1] as List<String>?),
      markSynced: afterSave,
    );
  }

  Future<void> _loadVisitor() async {
    String full = '';
    try {
      full = (await _visitorRepo.localName())?.trim() ?? '';
    } catch (_) {
      full = '';
    }
    if (!mounted) return;
    setState(() {
      _visitorFull = full;
    });
  }

  @override
  void dispose() {
    widget.condolencesController.removeListener(_onChanged);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Mensahe para kay Nanay, collected before lighting. Mandatory —
  /// the Sindihan button stays disabled until the draft is non-empty.
  final TextEditingController _messageController = TextEditingController();

  void _onMessageChanged() {
    if (mounted) setState(() {});
  }

  void _handleLightTap() {
    final controller = widget.condolencesController;
    if (controller.lit || controller.loading) return;
    // Mandatory message: the video-circle tap must respect the same gate
    // as the button, otherwise it would bypass validation.
    final draft = _messageController.text;
    if (CondolenceRepository.validateMessage(draft) != null) return;
    try {
      HapticFeedback.lightImpact().catchError((_) {});
    } catch (_) {
      // Haptics unavailable on desktop — the gesture still counts.
    }
    FocusManager.instance.primaryFocus?.unfocus();
    // Local-first: light immediately so offline web visitors are never
    // blocked, then save name + mensahe in the background (never throws).
    controller.lightCandle();
    final name = _visitorFull.trim().isEmpty ? 'Anonymous' : _visitorFull;
    controller.noteOwnLight(name);
    // ignore: discarded_futures — background sync, UI already lit.
    _condolenceRepo.saveMessage(name: name, message: draft).then((ok) {
      // Refresh the shared list once our candle is stored.
      if (ok && mounted) _loadRemote(afterSave: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final controller = widget.condolencesController;
    final lit = controller.lit;
    // Mandatory mensahe: the Sindihan button stays disabled until the
    // draft is non-empty and within limit. Name comes from the splash
    // gate; it is not re-shown as an attribution line here.
    final messageErrorKey = CondolenceRepository.validateMessage(
      _messageController.text,
    );
    final isMessageValid = messageErrorKey == null;

    return Column(
      children: [
        CandleVideo(lit: lit, onLight: _handleLightTap),
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
                  fontFamily: 'Lora',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.2,
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
                    fontFamily: 'Lora',
                    fontSize: 12.5,
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
        // Shared count: "{count} na ang nagsindi ng kandila
        // para kay Nanay Nita". Text-only, no leading icon.
        Text(
          lang.t(
            'candle_lit_times',
            {'count': '${controller.displayCount}'},
          ),
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            color: AppColors.muted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _FlameProgressRow(count: controller.displayCount),
        // Mensahe first (mandatory), then the single light action.
        // Hidden once lit — the video then rests on its final frame.
        // No second message box after lighting: thanks only.
        if (!lit) ...[
          const SizedBox(height: 16),
          _PreLightMessageField(
            controller: _messageController,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lang.t('candle_message_private_note'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 12.5,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (controller.loading || !isMessageValid)
                  ? null
                  : _handleLightTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmDark,
                foregroundColor: AppColors.linen,
                disabledBackgroundColor:
                    AppColors.stoneBorder.withValues(alpha: 0.6),
                disabledForegroundColor:
                    AppColors.muted.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                textStyle: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(lang.t('candle_light')),
                ],
              ),
            ),
          ),
          // Only show the error when there's actual input (e.g. too long).
          // Hiding the "required" hint on pristine empty field removes the
          // third duplicate line under the disabled button.
          if (messageErrorKey != null &&
              _messageController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              lang.t(messageErrorKey),
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.warmMid,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        const SizedBox(height: 20),
        // After lighting: thanks only, no second message box, then the
        // names-only remembering list (offline hides it).
        if (lit) ...[
          _RememberingList(
            controller: controller,
            onRetry: _loadRemote,
          ),
        ],
      ],
    );
  }
}

/// Names-only guestbook of who lit a candle, shown after Sindihan as a
/// fixed-size spiral notebook page with the binding on the left (like
/// loose-leaf). The page never grows: names scroll inside it.
/// Messages are never rendered here — too personal.
/// Offline (`recentNames == null`): the notebook stays but shows the
/// "go online" note with a retry button instead of lines.
class _RememberingList extends StatelessWidget {
  final CondolencesController controller;
  final Future<void> Function() onRetry;

  const _RememberingList({required this.controller, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final names = controller.recentNames;
    final loading = controller.listLoading;
    final hasList = names != null && names.isNotEmpty;
    final moreCount = (controller.remoteCount != null &&
            names != null &&
            controller.remoteCount! > names.length)
        ? controller.remoteCount! - names.length
        : 0;

    return _NotebookPaper(
      title: lang.t('candle_list_title'),
      child: loading && names == null
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            )
          : names == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.t('candle_list_offline'),
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.warmMid,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(lang.t('candle_list_retry')),
                    ),
                  ],
                )
              : names.isEmpty
                  ? Center(
                      child: Text(
                        lang.t('candle_list_empty'),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.warmMid,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _ScrollableNames(names: names),
                        ),
                        if (moreCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              lang.t(
                                'candle_list_more',
                                {'count': '$moreCount'},
                              ),
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.warmMid,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (!hasList) const SizedBox.shrink(),
                      ],
                    ),
    );
  }
}

/// Fixed-size spiral notebook page with the binding rail on the left.
/// [child] gets a fixed-height slot (page body) so long lists scroll
/// inside instead of growing the page.
class _NotebookPaper extends StatelessWidget {
  final String title;
  final Widget child;

  const _NotebookPaper({required this.title, required this.child});

  static const int _ringCount = 8;
  static const double _pageHeight = 340;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _pageHeight,
      child: Stack(
        children: [
          // Paper, inset so the rings can overhang the left edge.
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmDark.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              // Left inset clears the rings and doubles as the page's
              // binding margin; the right side stays tighter.
              padding: const EdgeInsets.fromLTRB(26, 14, 14, 14),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF5A4436),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
          // Left spiral binding: rings overhanging the paper edge.
          Positioned(
            left: 0,
            top: 32,
            bottom: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _ringCount; i++)
                  Container(
                    width: 20,
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color(0xFFD8CFC2),
                      border: Border.all(
                        color: const Color(0xFFBFB3A4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warmDark.withValues(alpha: 0.18),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable names inside the fixed notebook page: one dot + name per
/// ruled line. Own [ScrollController] so the bar only scrolls this list
/// and the page itself never expands, even with 100+ visitors.
class _ScrollableNames extends StatefulWidget {
  final List<String> names;

  const _ScrollableNames({required this.names});

  @override
  State<_ScrollableNames> createState() => _ScrollableNamesState();
}

class _ScrollableNamesState extends State<_ScrollableNames> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(2),
      child: ListView.builder(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        itemCount: widget.names.length,
        itemBuilder: (context, i) {
          return _NotebookLine(
            name: widget.names[i],
            isLast: i == widget.names.length - 1,
          );
        },
      ),
    );
  }
}

/// One ruled line in the notebook: dot bullet + handwritten-feel name,
/// underlined with a warm-grey rule like the reference photo.
class _NotebookLine extends StatelessWidget {
  final String name;
  final bool isLast;

  const _NotebookLine({
    required this.name,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFEDE6DA),
                  width: 1,
                ),
              ),
      ),
      // Left-aligned on the rule so the names sit against the binding
      // margin like handwriting on a ruled page (no dead gutter on the
      // left from a centered run).
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFCFC3B5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 14.5,
                height: 1.3,
                color: Color(0xFF6B5B4F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal flame progress row (Image 1): 7 outline flames centered,
/// first N filled warm brown where N = min(count, 7), rest light grey.
/// No hairline, no circles — flat modern feel, memorial tokens only.
class _FlameProgressRow extends StatelessWidget {
  final int count;

  const _FlameProgressRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final lit = count.clamp(0, 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 7; i++)
          Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 12),
            child: Icon(
              i < lit
                  ? Icons.local_fire_department_rounded
                  : Icons.local_fire_department_outlined,
              size: 22,
              color: i < lit ? AppColors.amber : AppColors.stoneBorder,
            ),
          ),
      ],
    );
  }
}

/// Minimal white message field (Image 1): radius 12, grey border,
/// no icon, no quote pill. Privacy line lives below it in the parent.
class _PreLightMessageField extends StatelessWidget {
  final TextEditingController controller;

  const _PreLightMessageField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stoneBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 1,
        maxLength: CondolenceRepository.maxMessageLength,
        buildCounter: (
          _, {
          required int currentLength,
          required bool isFocused,
          required int? maxLength,
        }) =>
            const SizedBox.shrink(),
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 14,
          color: AppColors.textDark,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: lang.t('candle_message_hint'),
          hintStyle: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            color: AppColors.muted,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
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
      Paint()..color = AppColors.haloCream.withValues(alpha: 0.95 * alpha),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CandleFlamePainter oldDelegate) {
    return oldDelegate.unfurl != unfurl || oldDelegate.glow != glow;
  }
}
