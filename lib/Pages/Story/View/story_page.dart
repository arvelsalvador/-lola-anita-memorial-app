import 'package:flutter/material.dart';
import 'package:nita/Pages/Story/Controller/story_controller.dart';
import 'package:nita/Pages/Story/Widget/story_widgets.dart';
import 'package:nita/Widgets/shared_widgets.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = StoryController.data;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SectionLabel('Her words'),
              const SizedBox(height: 12),
              QuoteCard(quote: data.quote, attribution: data.quoteAttribution),
              const SizedBox(height: 24),
              const SectionLabel('Her journey'),
              const SizedBox(height: 12),
              TimelineWidget(events: data.timeline),
              const SizedBox(height: 24),
              const SectionLabel('About her'),
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
