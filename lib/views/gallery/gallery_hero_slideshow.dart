part of 'gallery_page.dart';

/// Auto-rotating "featured memory" card above the grid.
///
/// Extracted from [_GalleryGridViewState] so its 5s [Timer] only rebuilds
/// this card — previously every tick called `setState` on the whole grid
/// state and relaid out the entire `CustomScrollView` + visible photo cards.
class HeroSlideshowCard extends StatefulWidget {
  final List<GalleryImageItem> images;
  final GalleryController galleryController;
  final ValueNotifier<int>? activeTab;

  const HeroSlideshowCard({
    super.key,
    required this.images,
    required this.galleryController,
    this.activeTab,
  });

  @override
  State<HeroSlideshowCard> createState() => _HeroSlideshowCardState();
}

class _HeroSlideshowCardState extends State<HeroSlideshowCard> {
  int _heroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    widget.activeTab?.addListener(_onTabChanged);
    final tab = widget.activeTab;
    if (tab == null || tab.value == 1) {
      _startHeroTimer();
    }
  }

  void _onTabChanged() {
    final isVisible = widget.activeTab?.value == 1;
    if (isVisible) {
      _startHeroTimer();
    } else {
      _heroTimer?.cancel();
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    if (widget.images.isEmpty) return;
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.images.isEmpty) return;
      setState(() {
        _heroIndex = (_heroIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant HeroSlideshowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.images, oldWidget.images)) {
      _heroIndex = 0;
      _startHeroTimer();
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    widget.activeTab?.removeListener(_onTabChanged);
    super.dispose();
  }

  Widget _heroCard(LanguageProvider lang) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final item = widget.images[_heroIndex % widget.images.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        button: true,
        label: lang.t('gallery_highlights'),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              final shuffled = List<GalleryImageItem>.of(widget.images)
                ..shuffle();
              Navigator.of(context).push(
                fadeRoute(
                  HighlightSlideshow(
                    images: shuffled,
                    galleryController: widget.galleryController,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.sandBorder, width: 1),
              ),
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    _heroPhotoStack(item),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang.t('gallery_highlights_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.copper,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              lang.t(item.date ?? 'date_1'),
                              key: ValueKey('date_$_heroIndex'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warmDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.copper,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.paper,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Three fanned photo cards (like a loose hand of photographs) instead
  /// of one swapping thumbnail. The front card shows the current
  /// _heroIndex photo with a play badge; the two behind it peek out from
  /// the corner, rotated slightly, so the stack reads as "there's more."
  Widget _heroPhotoStack(GalleryImageItem frontItem) {
    final count = widget.images.length;
    final backItem = count > 2 ? widget.images[(_heroIndex + 2) % count] : null;
    final midItem = count > 1 ? widget.images[(_heroIndex + 1) % count] : null;

    return SizedBox(
      width: 116,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (backItem != null)
            Positioned(
              left: 0,
              top: 14,
              child: Transform.rotate(
                angle: -0.22,
                child: _stackPhoto(backItem, size: 72, opacity: 0.55),
              ),
            ),
          if (midItem != null)
            Positioned(
              left: 16,
              top: 4,
              child: Transform.rotate(
                angle: -0.10,
                child: _stackPhoto(midItem, size: 82, opacity: 0.8),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _stackPhoto(
                frontItem,
                key: ValueKey(_heroIndex),
                size: 96,
                showPlay: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A single rounded, white-bordered photo tile used inside the fan
  /// stack. [showPlay] overlays a small play badge, used only on the
  /// front-most (active) card.
  Widget _stackPhoto(
    GalleryImageItem item, {
    required double size,
    double opacity = 1,
    bool showPlay = false,
    Key? key,
  }) {
    return Opacity(
      key: key,
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.paper, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.viewerBackground.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.path,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                cacheWidth: ImageDecode.width(200, context),
                errorBuilder: (c, e, s) => Container(
                  color: AppColors.cream,
                  child: const Icon(
                    Icons.photo_outlined,
                    size: 22,
                    color: AppColors.muted,
                  ),
                ),
              ),
              if (showPlay)
                Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.copper,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.paper,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _heroCard(lang);
  }
}

