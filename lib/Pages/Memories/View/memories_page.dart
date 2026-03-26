import 'package:flutter/material.dart';
import 'package:nita/Pages/Memories/Controller/memories_controller.dart';
import 'package:nita/Pages/Memories/Widget/memories_widget.dart';
import 'package:nita/Widgets/shared_widgets.dart';

class MemoriesPage extends StatelessWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MemoriesController.data;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const SectionLabel('Cherished memories'),
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
