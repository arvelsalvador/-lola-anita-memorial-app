import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/controllers/story_controller.dart';
import 'package:nita/widgets/story_widgets.dart';
import 'package:nita/widgets/section_label.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = StoryController.data;
    final lang = context.watch<LanguageProvider>();

    // primary: true so this scrollable attaches to the NestedScrollView and
    // drives the hero header away when scrolling.
    return CustomScrollView(
      primary: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SectionLabel(lang.t('section_her_words')),
              const SizedBox(height: 12),
              QuoteCard(
                quote: lang.t(data.quoteKey),
                attribution: lang.t(data.quoteAttributionKey),
              ),
              const SizedBox(height: 28),
              SectionLabel(lang.t('section_her_journey')),
              const SizedBox(height: 12),
              TimelineWidget(events: data.timeline),
              const SizedBox(height: 28),
              SectionLabel(lang.t('section_about_her')),
              const SizedBox(height: 12),
              AboutCard(text: lang.t(data.aboutKey)),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}
