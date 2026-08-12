import 'package:flutter/material.dart';

class GalleryImageItem {
  final String path;
  final String group;
  final String label;
  GalleryImageItem({
    required this.path,
    required this.group,
    required this.label,
  });
}

class ModernGalleryPage extends StatelessWidget {
  final List<GalleryImageItem> images;
  const ModernGalleryPage({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<GalleryImageItem>> grouped = {};
    for (final img in images) {
      grouped.putIfAbsent(img.group, () => []).add(img);
    }
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Gallery',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...grouped.entries.map((entry) => _buildGroup(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildGroup(String group, List<GalleryImageItem> images) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              group,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: images.length,
            itemBuilder: (context, i) => _GalleryImageTile(item: images[i]),
          ),
        ],
      ),
    );
  }
}

class _GalleryImageTile extends StatelessWidget {
  final GalleryImageItem item;
  const _GalleryImageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ← tap to open fullscreen
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullscreenImagePage(item: item)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            Image.asset(
              item.path,
              fit: BoxFit.cover,
              cacheWidth: 300,
              filterQuality: FilterQuality.low,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ← New fullscreen page
class FullscreenImagePage extends StatelessWidget {
  final GalleryImageItem item;
  const FullscreenImagePage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          item.label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          // ← pinch to zoom!
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.asset(
            item.path,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
