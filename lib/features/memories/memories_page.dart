import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/features/memories/memories_controller.dart';
import 'package:nita/features/memories/memory_card.dart';
import 'package:nita/shared/widgets/section_label.dart';

class MemoriesPage extends StatelessWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MemoriesController.data;
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: SectionLabel(lang.t('section_cherished_memories')),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MemoryCard(memory: data.memories[i]),
              ),
              childCount: data.memories.length,
            ),
          ),
        ),
      ],
    );
  }
}
