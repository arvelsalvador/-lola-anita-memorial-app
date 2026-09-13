import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/models/tribute_model.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/page_title_header.dart';

/// Words tab — the family's words for Lola Anita, redesigned to match the
/// new mockup: a serif title + italic subtitle, filter chips (Lahat /
/// Mga anak / Mga apo / Mga kapamilya), a pinned "Pinakaminamahal na
/// alaala" featured card, and one card per member with photo, name,
/// relation, quote, and a "Naiwan noong …" date footer.
/// Quote data comes from [TributeController.data] (featuredQuote +
/// familyQuotes), which is shared with (but untouched by) the condolences
/// candle feature.
class WordsPage extends StatefulWidget {
  final ScrollController? controller;

  /// Created by the home shell (composition root) and injected here — the
  /// view never constructs or owns the controller.
  final TributeController tributeController;

  const WordsPage({super.key, this.controller, required this.tributeController});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  QuoteGroup? _filter; // null = Lahat

  @override
  Widget build(BuildContext context) {
    final data = TributeController.data;
    final lang = context.watch<LanguageProvider>();

    final quotes = _filter == null
        ? data.familyQuotes
        : data.familyQuotes
            .where((q) => q.group == _filter)
            .toList(growable: false);

    return CustomScrollView(
      controller: widget.controller,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                // ── Title (shared Family page header design) ─────────
                PageTitleHeader(
                  title: lang.t('nav_words'),
                  subtitle: lang.t('words_subtitle'),
                ),
                const SizedBox(height: 18),
                // ── Filter chips ───────────────────────────────────────
                _FilterChips(
                  active: _filter,
                  onSelected: (group) => setState(() => _filter = group),
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
                _FeaturedQuoteCard(quote: data.featuredQuote),
                const SizedBox(height: 14),
              ],
              ...quotes.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FamilyQuoteCard(quote: q),
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
      IconData icon = Icons.group_outlined,
      VoidCallback? onTap,
    }) {
      return _FilterChip(
        label: label,
        icon: icon,
        selected: selected,
        onTap: onTap,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: lang.t('words_filter_all'),
            icon: Icons.grid_view_outlined,
            selected: active == null,
            onTap: active == null ? null : () => onSelected(null),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_children'),
            icon: Icons.family_restroom_outlined,
            selected: active == QuoteGroup.children,
            onTap: () => onSelected(
              active == QuoteGroup.children ? null : QuoteGroup.children,
            ),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_grandchildren'),
            icon: Icons.escalator_warning_outlined,
            selected: active == QuoteGroup.grandchildren,
            onTap: () => onSelected(
              active == QuoteGroup.grandchildren ? null : QuoteGroup.grandchildren,
            ),
          ),
          const SizedBox(width: 8),
          chip(
            label: lang.t('words_filter_siblings'),
            icon: Icons.diversity_3_outlined,
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
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.roseDeep : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.roseDeep
                  : AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.white : AppColors.warmMid,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.white : AppColors.warmMid,
                ),
              ),
            ],
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
          colors: [
            Color(0xFFFBF3E8),
            AppColors.goldLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
      child: Stack(
        children: [
          // Decorative rose pin, top-right — the ♥ marker from the mockup.
          const Positioned(
            top: 10,
            right: 12,
            child: Icon(Icons.favorite_rounded, size: 14, color: AppColors.rose),
          ),
          Padding(
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
                Text(
                  '\u201C',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 40,
                    color: AppColors.gold,
                    height: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                // ── Quote body (homepage serif-italic body type) ─────────
                Text(
                  '\u201C${lang.t(quote.quoteKey)}\u201D',
                  style: AppTextStyles.serifItalic.copyWith(
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
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.warmMid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One member quote card: circular photo avatar with a small heart badge,
/// big gold quotation mark, the quote, "— Name · Relation", and the
/// "Naiwan noong ..." footer on the right.
class FamilyQuoteCard extends StatelessWidget {
  final FamilyQuote quote;
  const FamilyQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return OrnamentalCard(
      radius: 14,
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
              // ── Avatar + heart badge ────────────────────────────────
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _MemberAvatar(
                      photoPath: quote.photoPath,
                      name: lang.t(quote.nameKey),
                      size: 46,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.warmDark,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 8,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Quote block ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201C${lang.t(quote.quoteKey)}\u201D',
                      style: AppTextStyles.serifItalic.copyWith(
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: AppColors.warmDark,
                            ),
                          ),
                          TextSpan(
                            text: '   ${lang.t(quote.relationKey)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
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
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
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
    if (photoPath == null) {
      return GradientAvatar(
        size: size,
        initials: _initialsOf(name),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
        image: DecorationImage(
          image: AssetImage(photoPath!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
