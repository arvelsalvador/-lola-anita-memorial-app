import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/display_utils.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/controllers/words_controller.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/data/guide/guide_repository.dart';
import 'package:nita/models/words_model.dart';
import 'package:nita/views/guide/guide_page.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/page_title_header.dart';
import 'package:nita/widgets/reveal_on_appear.dart';

/// Words tab — the family's words for Lola Anita, redesigned to match the
/// new mockup: a serif title + italic subtitle, filter chips (Lahat /
/// Mga anak / Mga apo / Mga kapamilya), a pinned "Pinakaminamahal na
/// alaala" featured card, and one card per member with photo, name,
/// relation, quote, and a "Naiwan noong …" date footer.
/// Quote data comes from [WordsController.data] (featuredQuote +
/// familyQuotes), which is shared with (but untouched by) the condolences
/// candle feature.
class WordsPage extends StatefulWidget {
  final ScrollController? controller;

  /// Reports the active tab index from the home shell, so the guide knows
  /// when the Words tab (3) is actually open.
  final ValueNotifier<int>? activeTab;

  /// Bumped by the shell's top-bar `?` to replay the Words guide.
  final ValueListenable<int>? guideRequests;

  /// Created by the home shell (composition root) and injected here — the
  /// view never constructs or owns the controller.
  final WordsController wordsController;

  const WordsPage({
    super.key,
    this.controller,
    this.activeTab,
    this.guideRequests,
    required this.wordsController,
  });

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  static const int _wordsTab = 3;

  QuoteGroup? _filter; // null = Lahat

  /// Marks the filter-pills row, the guide's lit target.
  final GlobalKey _filterPillsKey = GlobalKey();

  /// Published to the guide so the hole stays glued to the filter pills row.
  final ValueNotifier<Rect?> _filterPillsRect = ValueNotifier<Rect?>(null);

  /// One-shot guard so the guide is scheduled at most once per page instance.
  bool _guideCheckStarted = false;

  /// True while the guide route is on screen.
  bool _guideOpen = false;

  @override
  void initState() {
    super.initState();
    widget.activeTab?.addListener(_onActiveTabChanged);
    widget.guideRequests?.addListener(_onGuideRequested);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {},
    );
  }

  @override
  void didUpdateWidget(covariant WordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeTab, widget.activeTab)) {
      oldWidget.activeTab?.removeListener(_onActiveTabChanged);
      widget.activeTab?.addListener(_onActiveTabChanged);
    }
    if (!identical(oldWidget.guideRequests, widget.guideRequests)) {
      oldWidget.guideRequests?.removeListener(_onGuideRequested);
      widget.guideRequests?.addListener(_onGuideRequested);
    }
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onActiveTabChanged);
    widget.guideRequests?.removeListener(_onGuideRequested);
    _filterPillsRect.dispose();
    super.dispose();
  }

  void _onActiveTabChanged() {
    // Managed by GuideController.
  }

  void _onGuideRequested() => _maybeShowWordsGuide(replay: true);

  void _maybeShowWordsGuide({bool replay = false}) {
    if (_guideOpen) return;
    if (!replay && _guideCheckStarted) return;
    if (widget.activeTab?.value != _wordsTab) return;
    _guideCheckStarted = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openWordsGuide(replay: replay),
    );
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _openWordsGuide({bool replay = false}) async {
    if (!mounted || _guideOpen || widget.activeTab?.value != _wordsTab) {
      return;
    }

    if (!replay) {
      final seen = await const GuideRepository.words().hasSeen();
      if (!mounted || seen || widget.activeTab?.value != _wordsTab) return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      if (!replay) _guideCheckStarted = false;
      return;
    }

    // HomeShell resets the new tab's scroll offset and fades in on the frame
    // after activeTab changes; wait for that frame so the scroll reset has
    // already landed before measuring the filter pills row.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _guideOpen || widget.activeTab?.value != _wordsTab) {
      return;
    }

    final scrollController = widget.controller;
    if (scrollController != null &&
        scrollController.hasClients &&
        scrollController.position.pixels > 0) {
      scrollController.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _guideOpen || widget.activeTab?.value != _wordsTab) {
        return;
      }
    }

    // Retry for a few frames if the pills row isn't laid out or on-screen yet.
    var rect = _pillsRectOnScreen();
    for (var i = 0; i < 6 && rect == null; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _guideOpen || widget.activeTab?.value != _wordsTab) {
        return;
      }
      rect = _pillsRectOnScreen();
    }
    _filterPillsRect.value = rect;

    _guideOpen = true;
    Navigator.of(context)
        .push(
          fadeRoute(
            GuidePage(
              tour: GuideTour.words,
              wordsFilterPillsRect: _filterPillsRect,
            ),
            opaque: false,
          ),
        )
        .then((_) {
          if (!mounted) return;
          _guideOpen = false;
        });
    _refreshPillsRect(attempts: 6);
  }

  void _refreshPillsRect({int attempts = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_guideOpen) return;
      final rect = _pillsRectOnScreen();
      if (rect != _filterPillsRect.value) _filterPillsRect.value = rect;
      if (attempts > 0) {
        _refreshPillsRect(attempts: attempts - 1);
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Rect? _pillsRectOnScreen() {
    final box = _filterPillsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.top < 0 || rect.bottom > screen.height) return null;
    return Rect.fromLTRB(
      rect.left - 10,
      rect.top - 5,
      rect.right + 10,
      rect.bottom + 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    const data = WordsController.data;
    final lang = context.watch<LanguageProvider>();
    final locked = context.watch<GuideController?>()?.inputLocked ?? false;

    final quotes = _filter == null
        ? data.familyQuotes
        : data.familyQuotes
              .where((q) => q.group == _filter)
              .toList(growable: false);

    return CustomScrollView(
      controller: widget.controller,
      primary: false,
      physics: locked ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                // ── Title (shared Family page header design) ─────────
                RevealOnAppear(
                  id: 'words-header',
                  index: 0,
                  child: PageTitleHeader(
                    title: lang.t('nav_words'),
                    subtitle: lang.t('words_subtitle'),
                  ),
                ),
                const SizedBox(height: 18),
                // ── Filter chips ───────────────────────────────────────
                RevealOnAppear(
                  id: 'words-filter-pills',
                  index: 1,
                  child: Center(
                    child: KeyedSubtree(
                      key: _filterPillsKey,
                      child: _FilterChips(
                        active: _filter,
                        onSelected: (group) => setState(() => _filter = group),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Featured card (only on "Lahat") ──────────────────────
              if (_filter == null) ...[
                RevealOnAppear(
                  id: 'words-featured',
                  index: 2,
                  floatUp: true,
                  child: _FeaturedQuoteCard(quote: data.featuredQuote),
                ),
                const SizedBox(height: 14),
              ],
              for (var i = 0; i < quotes.length; i++)
                Padding(
                  key: ValueKey(quotes[i].quoteKey),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RevealOnAppear(
                    id: 'words-quote-${quotes[i].quoteKey}',
                    index: 3 + i,
                    floatUp: true,
                    animate: i < 6,
                    child: FamilyQuoteCard(quote: quotes[i]),
                  ),
                ),
              if (quotes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    lang.t('words_empty'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.homeContent.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

/// The horizontal "Lahat / Mga anak / Mga apo / Mga kapamilya" chip row.
/// Tapping the active chip again returns to "Lahat".
class _FilterChips extends StatelessWidget {
  final QuoteGroup? active;
  final ValueChanged<QuoteGroup?> onSelected;

  const _FilterChips({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    Widget chip({
      required String label,
      required bool selected,
      VoidCallback? onTap,
    }) {
      return _FilterChip(label: label, selected: selected, onTap: onTap);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: lang.t('words_filter_all'),
            selected: active == null,
            onTap: active == null ? null : () => onSelected(null),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_children'),
            selected: active == QuoteGroup.children,
            onTap: () => onSelected(
              active == QuoteGroup.children ? null : QuoteGroup.children,
            ),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_grandchildren'),
            selected: active == QuoteGroup.grandchildren,
            onTap: () => onSelected(
              active == QuoteGroup.grandchildren
                  ? null
                  : QuoteGroup.grandchildren,
            ),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_siblings'),
            selected: active == QuoteGroup.siblings,
            onTap: () => onSelected(
              active == QuoteGroup.siblings ? null : QuoteGroup.siblings,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.roseDeep : AppColors.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          // Elderly visitors tap these by hand — the former ~36px height
          // was under the 44–48dp minimum the rest of the app enforces
          // (see AppBottomNav). A minimum height constraint keeps the
          // chip's visual look while guaranteeing the tap target.
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.roseDeep
                  : AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.homeContent.copyWith(
              color: selected ? AppColors.paper : AppColors.warmMid,
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned "Pinakaminamahal na alaala" card — cream-tinted, gold-framed,
/// with a large decorative quotation mark and centered "— Pamilya" footer.
class _FeaturedQuoteCard extends StatelessWidget {
  final FamilyQuote quote;

  const _FeaturedQuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.quotePaper, AppColors.goldLight],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label row ────────────────────────────────────────
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '· ${lang.t('words_featured_label')} ·',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: AppColors.roseDeep,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Big open-quote mark (homepage QuoteCard style) ─────
            const Text(
              '\u201C',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                color: AppColors.gold,
                height: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            // ── Quote body (homepage serif-italic body type) ─────────
            Text(
              '\u201C${lang.t(quote.quoteKey)}\u201D',
              style: AppTextStyles.bodyQuote.copyWith(
                fontSize: 17,
                height: 1.55,
                color: AppColors.warmDark,
              ),
            ),
            const SizedBox(height: 10),
            // ── Footer line ──────────────────────────────────────
            Row(
              children: [
                const SizedBox(width: 24),
                Text(
                  '\u2014 ${lang.t(quote.nameKey)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.warmMid,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One member quote card: circular photo avatar, the quote,
/// "— Name · Relation", and the "Naiwan noong ..." footer on the right.
class FamilyQuoteCard extends StatelessWidget {
  final FamilyQuote quote;
  const FamilyQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return OrnamentalCard(
      radius: 12,
      borderColor: AppColors.gold,
      borderAlpha: 0.3,
      borderWidth: 0.7,
      shadowOpacity: 0.07,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────
              _MemberAvatar(
                photoPath: quote.photoPath,
                name: lang.t(quote.nameKey),
                size: 46,
              ),
              const SizedBox(width: 12),
              // ── Quote block ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201C${lang.t(quote.quoteKey)}\u201D',
                      style: AppTextStyles.bodyQuote.copyWith(
                        fontSize: 13.5,
                        height: 1.55,
                        color: AppColors.warmDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '\u2014 ${lang.t(quote.nameKey)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warmDark,
                            ),
                          ),
                          TextSpan(
                            text: '   ${lang.t(quote.relationKey)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.roseDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Date footer, right-aligned ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  lang.t(quote.dateKey),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular member photo with a gold ring; falls back to a gradient
/// initials avatar when [photoPath] is null.
class _MemberAvatar extends StatelessWidget {
  final String? photoPath;
  final String name;
  final double size;

  const _MemberAvatar({
    required this.photoPath,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path == null || path.isEmpty) {
      return GradientAvatar(size: size, initials: _initialsOf(name));
    }
    // ClipOval + Image.asset (with errorBuilder) instead of
    // DecorationImage — a missing bundled photo falls back to initials
    // instead of throwing a red-screen paint error.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          cacheWidth: ImageDecode.width(size, context),
          errorBuilder: (_, _, _) =>
              GradientAvatar(size: size, initials: _initialsOf(name)),
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    return DisplayUtils.initialsOf(name).toUpperCase();
  }
}
