import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/tribute_controller.dart';
import 'package:nita/widgets/tribute_widgets.dart';
import 'package:nita/widgets/section_label.dart';

class TributePage extends StatelessWidget {
  const TributePage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = TributeController.data;
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SectionLabel(lang.t('section_final_tribute')),
              const SizedBox(height: 12),
              TributeMainCard(message: data.tributeMessage),
              const SizedBox(height: 20),
              SectionLabel(lang.t('section_words_family')),
              const SizedBox(height: 12),
              ...data.familyQuotes.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FamilyQuoteCard(quote: q),
                ),
              ),
              const SizedBox(height: 12),
              const CandleSection(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}
