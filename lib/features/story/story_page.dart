import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/features/story/story_controller.dart';
import 'package:nita/features/story/story_widgets.dart';
import 'package:nita/shared/widgets/section_label.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = StoryController.data;
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SectionLabel(lang.t('section_her_words')),
              const SizedBox(height: 12),
              QuoteCard(quote: data.quote, attribution: data.quoteAttribution),
              const SizedBox(height: 24),
              SectionLabel(lang.t('section_her_journey')),
              const SizedBox(height: 12),
              TimelineWidget(events: data.timeline),
              const SizedBox(height: 24),
              SectionLabel(lang.t('section_about_her')),
              const SizedBox(height: 12),
              AboutCard(text: data.about),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}
