import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/models/tribute_model.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/section_label.dart';

class TributePage extends StatelessWidget {
  final ScrollController? controller;

  /// Created by the home shell (composition root) and injected here — the
  /// view never constructs or owns the controller.
  final TributeController tributeController;

  const TributePage({
    super.key,
    this.controller,
    required this.tributeController,
  });

  @override
  Widget build(BuildContext context) {
    final data = TributeController.data;
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      controller: controller,
      primary: false,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SectionLabel(lang.t('section_final_tribute')),
              const SizedBox(height: 12),
              TributeMainCard(message: lang.t(data.tributeMessageKey)),
              const SizedBox(height: 24),
              SectionLabel(lang.t('section_words_family')),
              const SizedBox(height: 12),
              ...data.familyQuotes.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FamilyQuoteCard(quote: q),
                ),
              ),
              const SizedBox(height: 12),
              CandleSection(tributeController: tributeController),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class TributeMainCard extends StatelessWidget {
  final String message;
  const TributeMainCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.warmDark, AppColors.warmDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text(
            lang.t('tribute_until_we_meet'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Color(0xFFFAF0E6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lang.t('tribute_in_loving_memory'),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.gold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 50,
            height: 0.8,
            color: AppColors.gold.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: Color(0xFFD4BFB5),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyQuoteCard extends StatelessWidget {
  final FamilyQuote quote;
  const FamilyQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return OrnamentalCard(
      radius: 14,
      borderColor: AppColors.gold,
      borderAlpha: 0.25,
      borderWidth: 0.5,
      shadowOpacity: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201C${lang.t(quote.quoteKey)}\u201D',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: AppColors.warmMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u2014 ${lang.t(quote.nameKey)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class CandleSection extends StatefulWidget {
  final TributeController tributeController;

  const CandleSection({super.key, required this.tributeController});

  @override
  State<CandleSection> createState() => _CandleSectionState();
}

class _CandleSectionState extends State<CandleSection> {
  @override
  void initState() {
    super.initState();
    widget.tributeController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.tributeController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return OrnamentalCard(
      fill: AppColors.goldLight,
      radius: 16,
      borderColor: AppColors.gold,
      borderAlpha: 0.3,
      borderWidth: 0.5,
      shadowOpacity: 0,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.72),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 0.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(
                    alpha: widget.tributeController.lit ? 0.35 : 0.12,
                  ),
                  blurRadius: widget.tributeController.lit ? 28 : 12,
                  spreadRadius: widget.tributeController.lit ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              widget.tributeController.lit
                  ? Icons.local_fire_department_rounded
                  : Icons.light_mode_rounded,
              color: widget.tributeController.lit
                  ? AppColors.rose
                  : AppColors.gold,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.tributeController.lit
                ? lang.t('candle_lit')
                : lang.t('candle_light'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              color: AppColors.warmDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: widget.tributeController.candleStream,
            builder: (context, snapshot) {
              int count = widget.tributeController.localCount;
              if (!snapshot.hasError &&
                  snapshot.hasData &&
                  snapshot.data!.exists) {
                final data = snapshot.data!.data();
                final remoteCount = data?['candleCount'];
                if (remoteCount is int) count = remoteCount;
              }
              return Text(
                '$count ${lang.t('candle_virtual')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warmMid,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                widget.tributeController.lit || widget.tributeController.loading
                ? null
                : widget.tributeController.lightCandle,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.tributeController.lit
                  ? AppColors.gold
                  : AppColors.warmDark,
              foregroundColor: const Color(0xFFFAF0E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              widget.tributeController.lit
                  ? lang.t('candle_thank_you')
                  : lang.t('candle_light'),
              style: const TextStyle(fontSize: 13, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
