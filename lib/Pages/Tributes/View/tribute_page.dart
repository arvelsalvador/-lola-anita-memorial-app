import 'package:flutter/material.dart';
import 'package:nita/Pages/Tributes/Controller/tribute_controller.dart';
import 'package:nita/Pages/Tributes/Widget/tribute_widgets.dart';
import 'package:nita/Widgets/shared_widgets.dart';

class TributePage extends StatelessWidget {
  const TributePage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = TributeController.data;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SectionLabel('A final tribute'),
              const SizedBox(height: 12),
              TributeMainCard(message: data.tributeMessage),
              const SizedBox(height: 20),
              const SectionLabel('Words from the family'),
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
