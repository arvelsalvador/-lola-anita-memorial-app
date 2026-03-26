import 'package:flutter/material.dart';
import 'package:nita/Pages/Gallery/Controller/gallery_controller.dart';
import 'package:nita/Pages/Gallery/Widget/gallery_widget.dart';
import 'package:nita/Widgets/shared_widgets.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = GalleryController.data;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const SectionLabel('A life in pictures'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => PhotoTile(photo: data.photos[i]),
              childCount: data.photos.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
          ),
        ),
      ],
    );
  }
}
