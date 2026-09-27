part of 'gallery_page.dart';

class GalleryLightbox extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;

  /// Shared consent state ("which Remembrance photos has the visitor
  /// consented to see") owned by GalleryController — the same source of
  /// truth the grid uses, so revealing a photo here unlocks it in the
  /// grid too, and vice versa.
  final GalleryController galleryController;

  const GalleryLightbox({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.galleryController,
  });

  @override
  State<GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<GalleryLightbox> {
  // Absolute pixel decode budget for the zoomable lightbox (the
  // InteractiveViewer scales up to 3×), not a logical size — deliberately
  // NOT DPR-multiplied, or high-DPI devices would decode 3000px+ bitmaps.
  static const _lightboxWidth = 1080;

  late final PageController _controller = PageController(
    initialPage: _clampedInitial,
  );
  late int _current = _clampedInitial;

  int get _clampedInitial {
    if (widget.images.isEmpty) return 0;
    return widget.initialIndex.clamp(0, widget.images.length - 1);
  }

  @override
  void initState() {
    super.initState();
    // Warm the current + neighbor pages at viewer resolution so swipes
    // land on decoded bitmaps instead of janking on full-res decodes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheNeighbors(_current);
    });
  }

  void _precacheNeighbors(int index) {
    for (final i in {index - 1, index, index + 1}) {
      if (i >= 0 && i < widget.images.length) {
        precacheImage(
          ResizeImage(AssetImage(widget.images[i].path), width: _lightboxWidth),
          context,
        );
      }
    }
  }

  bool _isLocked(int index) =>
      widget.images[index].group == GalleryGroup.remembrances &&
      !widget.galleryController.isUnlocked(widget.images[index].path);

  Widget _navArrow({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (widget.images.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.viewerBackground,
        body: Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      );
    }
    final item = widget.images[_current.clamp(0, widget.images.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) {
              setState(() => _current = i);
              _precacheNeighbors(i);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, i) {
              final image = widget.images[i];
              final locked = _isLocked(i);
              final viewer = InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: Center(
                  child: Hero(
                    tag: 'gallery_${image.path}',
                    child: Image.asset(
                      image.path,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      // Viewer tier: bounded decode instead of native
                      // camera resolution (grid uses ~200-400).
                      cacheWidth: _lightboxWidth,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
              if (!locked) return viewer;
              // Sacred photos stay blurred until the visitor taps to see
              // them in full.
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: viewer,
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => widget.galleryController.unlock(image.path),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        // Warm golden veil instead of a grey one.
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.glowGold.withValues(alpha: 0.16),
                            AppColors.gold.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.paper.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.55),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: const Icon(
                              // The same candle flame that waits behind the
                              // Last Day gate.
                              Icons.local_fire_department_rounded,
                              size: 32,
                              color: AppColors.amber,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.t('gallery_tap_to_reveal'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.candleGlow,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ViewerChrome(
              current: _current,
              total: widget.images.length,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),

          if (_current > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _navArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
          if (_current < widget.images.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _navArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
          if (!_isLocked(_current))
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_current),
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    decoration: BoxDecoration(
                      // Higher-opacity dark base plus a subtle warm
                      // gradient at the top edge, so the card reads as
                      // a distinct surface rather than blending into
                      // the black backdrop behind the photo.
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.78),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Small accent line above the title draws the
                        // eye to the card before you even read the text.
                        Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang.t(item.group.key),
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppColors.paper,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 13,
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                lang.t(item.location ?? 'loc_lipa'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text(
                              '   •   ',
                              style: TextStyle(color: Colors.white38),
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                lang.t(item.date ?? 'date_1'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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

/// Top overlay for the full-screen photo viewer: a close button
/// (top-right) and a "current / total" counter pill (top-left).
/// Lives here (not the page shell) because the lightbox is its only user.
class _ViewerChrome extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onClose;

  const _ViewerChrome({
    required this.current,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 38,
            ), // balances the close button's width so the counter stays centered
            Expanded(
              child: Text(
                '${current + 1} / $total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _chromeIconButton(icon: Icons.close_rounded, onTap: onClose),
          ],
        ),
      ),
    );
  }

  Widget _chromeIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.viewerBackground.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.paper, size: 22),
        ),
      ),
    );
  }
}

