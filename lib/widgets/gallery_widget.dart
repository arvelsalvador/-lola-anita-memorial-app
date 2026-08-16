import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/widgets/highlight_slideshow.dart';

const List<String> _groupOrder = [
  'group_celebrations',
  'group_bahay',
  'group_family',
  'group_care',
  'group_gatherings',
  'group_portraits',
  'group_remembrances',
  'group_other',
];

class GalleryGridView extends StatefulWidget {
  final List<GalleryImageItem> images;
  const GalleryGridView({super.key, required this.images});

  @override
  State<GalleryGridView> createState() => _GalleryGridViewState();
}

class _GalleryGridViewState extends State<GalleryGridView> {
  String? _selectedGroup;

  List<GalleryImageItem> get _filtered => _selectedGroup == null
      ? widget.images
      : widget.images.where((i) => i.group == _selectedGroup).toList();

  List<String> get _groups {
    final ordered = <String>[];
    final seen = <String>{};
    for (final key in _groupOrder) {
      if (widget.images.any((i) => i.group == key)) {
        ordered.add(key);
        seen.add(key);
      }
    }
    for (final img in widget.images) {
      if (!seen.contains(img.group)) {
        seen.add(img.group);
        ordered.add(img.group);
      }
    }
    return ordered;
  }

  int _columnsFor(double width) =>
      width >= 900 ? 4 : width >= 620 ? 3 : 2;

  void _openLightbox(List<GalleryImageItem> images, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, _, _) =>
            GalleryLightbox(images: images, initialIndex: index),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final images = _filtered;

    return CustomScrollView(
      primary: false,
      slivers: [
        SliverToBoxAdapter(child: _header(lang)),
        SliverToBoxAdapter(child: _chips(lang)),
        if (_selectedGroup != null)
          SliverToBoxAdapter(child: _highlightsBanner(lang, images)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: _columnsFor(MediaQuery.sizeOf(context).width),
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childCount: images.length,
            itemBuilder: (context, index) => _PhotoCard(
              item: images[index],
              index: index,
              showGroupTag: _selectedGroup == null,
              onTap: () => _openLightbox(images, index),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _header(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('nav_gallery'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.warmDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lang.t('gallery_subtitle'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.local_florist_rounded,
                size: 14,
                color: AppColors.gold.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 0.8,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips(LanguageProvider lang) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(lang, null),
          for (final group in _groups) _chip(lang, group),
        ],
      ),
    );
  }

  Widget _highlightsBanner(LanguageProvider lang, List<GalleryImageItem> images) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: true,
                pageBuilder: (_, _, _) =>
                    HighlightSlideshow(images: images),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 260),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.warmDark, Color(0xFF5A3A2B)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmDark.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.warmDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('gallery_highlights'),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${images.length} ${lang.t('gallery_photos')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.movie_rounded,
                  color: AppColors.goldLight,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(LanguageProvider lang, String? group) {
    final selected = _selectedGroup == group;
    final label = group == null ? lang.t('gallery_all') : lang.t(group);
    final count = group == null
        ? widget.images.length
        : widget.images.where((i) => i.group == group).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.warmDark : AppColors.white,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () => setState(() => _selectedGroup = group),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.gold.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.warmMid,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.goldLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.goldLight : AppColors.warmMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final GalleryImageItem item;
  final int index;
  final bool showGroupTag;
  final VoidCallback onTap;

  static const List<double> _ratios = [1.1, 1.5, 0.95, 1.3, 0.85, 1.4];

  const _PhotoCard({
    required this.item,
    required this.index,
    required this.showGroupTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final ratio = _ratios[index % _ratios.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Interval((index % 8) * 0.07, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: 'gallery_${item.path}',
          child: AspectRatio(
            aspectRatio: ratio,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmDark.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  width: 0.6,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.cream,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    item.path,
                    fit: BoxFit.cover,
                    cacheWidth: 400,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (c, e, s) => Container(
                      color: AppColors.cream,
                      child: const Icon(
                        Icons.broken_image,
                        size: 32,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.warmDark.withValues(alpha: 0.55),
                        ],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                  if (showGroupTag)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_florist_rounded,
                              size: 10,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lang.t(item.group),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warmDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 11,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                lang.t(item.location ?? 'loc_lipa'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 9,
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lang.t(item.date ?? 'date_1'),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GalleryLightbox extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;

  const GalleryLightbox({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<GalleryLightbox> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final item = widget.images[_current];

    return Scaffold(
      backgroundColor: const Color(0xFF17110D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.images.length,
            itemBuilder: (context, i) {
              final image = widget.images[i];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Hero(
                    tag: 'gallery_${image.path}',
                    child: Image.asset(
                      image.path,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 12,
                  child: FloatingCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_current),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.t(item.group),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              lang.t(item.location ?? 'loc_lipa'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(color: Colors.white38),
                          ),
                          Flexible(
                            child: Text(
                              lang.t(item.date ?? 'date_1'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}