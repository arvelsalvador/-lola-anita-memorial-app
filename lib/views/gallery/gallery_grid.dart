part of 'gallery_page.dart';

class GalleryGridView extends StatefulWidget {
  final List<GalleryImageItem> images;
  final ScrollController? controller;
  final ValueNotifier<int>? activeTab;
  final GalleryController galleryController;
  const GalleryGridView({
    super.key,
    required this.images,
    this.controller,
    this.activeTab,
    required this.galleryController,
  });

  @override
  State<GalleryGridView> createState() => _GalleryGridViewState();
}

class _GalleryGridViewState extends State<GalleryGridView>
    with TickerProviderStateMixin {
  GalleryGroup? _selectedGroup;
  // Search text the visitor typed. Empty string = no search filter.
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Tracks whether the filter-pill row can still scroll further right,
  // so the edge fade only shows when it's actually true — not as a
  // permanent decoration that lingers even at the end of the list.
  final ScrollController _pillsScrollController = ScrollController();
  bool _pillsCanScrollMore = false;

  final Set<GalleryGroup> _visited = {};

  // Featured-memory rotation lives in [HeroSlideshowCard] so its 5s timer
  // never rebuilds this grid state.

  Widget _searchBar(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stoneBorder, width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(fontSize: 14, color: AppColors.warmDark),
          decoration: InputDecoration(
            hintText: lang.t('gallery_search_hint'),
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.muted,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  /// Plain-text pills — "Lahat" (all) plus one per category. No leading
  /// icons and a rounded-rectangle shape rather than a full capsule, to
  /// match the simpler reference design.
  Widget _filterPills(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Taller than the pills themselves so Lora's descenders
          // (the tails of "g" in "Pagdiriwang") are never clipped by
          // the horizontal ListView's edge.
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.paper,
                  AppColors.paper,
                  // No fade at all once there's nothing left to scroll
                  // to — the gradient becomes fully opaque white,
                  // meaning BlendMode.dstIn changes nothing.
                  _pillsCanScrollMore ? Colors.transparent : AppColors.paper,
                ],
                stops: const [0.0, 0.92, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: ListView(
                controller: _pillsScrollController,
                scrollDirection: Axis.horizontal,
                children: [
                  _filterPill(
                    label: lang.t('gallery_all'),
                    selected: _selectedGroup == null,
                    onTap: () => _selectGroup(null),
                  ),
                  for (final group in _groups) ...[
                    const SizedBox(width: 8),
                    _filterPill(
                      label: lang.t(group.key),
                      selected: _selectedGroup == group,
                      onTap: () => _onFilterTap(group),
                      // The Last Day pill gets its own warm/gold look so
                      // it reads as a distinct, meaningful section worth
                      // tapping into — not just another category.
                      isRemembrances: group == GalleryGroup.remembrances,
                    ),
                  ],
                  // Extra trailing space so the ShaderMask's fade doesn't
                  // permanently dim the last real pill when the row isn't
                  // scrolled — the fade now eases into empty padding
                  // instead of the final chip's label.
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
          if (_selectedGroup != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton(
                onPressed: () {
                  _selectGroup(null);
                  // Scroll the pill row back to the start so "All"
                  // (now active) is actually visible, not just selected
                  // off-screen.
                  if (_pillsScrollController.hasClients) {
                    _pillsScrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  lang.t('gallery_clear_all'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.copper,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isRemembrances = false,
  }) {
    // Unselected Remembrances pill: gold border + flame icon, so it
    // stands out from ordinary category pills even before it's tapped.
    // Selected state still falls back to the same warm-brown fill as
    // every other active pill, for a consistent "this is active" signal.
    final unselectedBg = isRemembrances
        ? AppColors.gold.withValues(alpha: 0.14)
        : AppColors.paper;
    final unselectedBorder = isRemembrances
        ? AppColors.gold
        : AppColors.stoneBorder;
    final unselectedTextColor = isRemembrances
        ? AppColors.amber
        : AppColors.warmDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.copper : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : unselectedBorder,
              width: isRemembrances && !selected ? 1.4 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRemembrances) ...[
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: selected ? AppColors.paper : unselectedTextColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: selected ? AppColors.paper : unselectedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectGroup(GalleryGroup? group) {
    setState(() {
      _selectedGroup = group;
      if (_selectedGroup != GalleryGroup.remembrances) {
        widget.galleryController.resetUnlocked();
      }
    });
  }

  Future<void> _onFilterTap(GalleryGroup group) async {
    if (group == GalleryGroup.remembrances && _selectedGroup != group) {
      final count = widget.images.where((i) => i.group == group).length;
      final lit = await Navigator.of(context).push<bool>(
        fadeRoute(
          CandleGate(photoCount: count),
          duration: const Duration(milliseconds: 400),
        ),
      );
      if (lit != true || !mounted) return;
    }
    _selectGroup(_selectedGroup == group ? null : group);
  }

  /// Section header: "Mga alaala" on the left, photo count on the right.
  /// The title yields via [Expanded] so long translations can never push
  /// the count (or the row) past the edge — this overflowed 14px in wide
  /// test fonts once image counts loaded in.
  Widget _listHeader(LanguageProvider lang, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              lang.t('gallery_all_photos_label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.warmDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${lang.t('gallery_photos')}',
            maxLines: 1,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.activeTab?.addListener(_onTabChanged);
    _pillsScrollController.addListener(_updatePillsFade);
    // Check once after the first frame, in case there are enough pills
    // to overflow even before the user touches the row.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePillsFade());
    // One fixed shuffle order per page instance: the "Lahat na Larawan"
    // grid shows the photos in a mixed-up order instead of the sorted
    // source order. Built once in initState so the grid doesn't reshuffle
    // on filter/search setStates.
    _shuffleRandom = math.Random();
  }

  void _updatePillsFade() {
    if (!mounted) return;
    if (!_pillsScrollController.hasClients) return;
    final position = _pillsScrollController.position;
    // "Can scroll more" means we're not already within half a pixel of
    // the end — a small epsilon avoids float-precision flicker right at
    // the boundary.
    final canScrollMore = position.maxScrollExtent - position.pixels > 0.5;
    if (canScrollMore != _pillsCanScrollMore) {
      setState(() => _pillsCanScrollMore = canScrollMore);
    }
  }

  late final math.Random _shuffleRandom;

  /// The photos in shuffled order — computed once, then reused so every
  /// rebuild shows the same mixed order.
  late final List<GalleryImageItem> _shuffledImages = () {
    final list = List<GalleryImageItem>.of(widget.images);
    list.shuffle(_shuffleRandom);
    return list;
  }();

  void _onTabChanged() {
    if (!mounted) return;
    // The gallery is tab index 1 in the home shell. The hero card owns
    // its own rotation timer (see [HeroSlideshowCard]); here we only
    // reset entrance-visit tracking.
    if (widget.activeTab?.value == 1) {
      if (_visited.isNotEmpty && mounted) setState(_visited.clear);
    }
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onTabChanged);
    _searchController.dispose();
    _pillsScrollController.dispose();
    super.dispose();
  }

  List<GalleryImageItem> get _filtered {
    // "All" deliberately excludes Remembrances — those locked photos only
    // appear once the visitor explicitly taps that category (and passes
    // the candle gate), not mixed anonymously into the general grid. It
    // also shows the photos in shuffled order (one fixed order per visit);
    // a specific category keeps the source order so related photos stay
    // together.
    final byGroup = _selectedGroup == null
        ? _shuffledImages
              .where((i) => i.group != GalleryGroup.remembrances)
              .toList()
        : widget.images.where((i) => i.group == _selectedGroup).toList();

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return byGroup;

    final lang = context.read<LanguageProvider>();
    return byGroup.where((item) {
      final group = lang.t(item.group.key).toLowerCase();
      final date = lang.t(item.date ?? 'date_1').toLowerCase();
      final location = lang.t(item.location ?? 'loc_lipa').toLowerCase();
      return group.contains(query) ||
          date.contains(query) ||
          location.contains(query);
    }).toList();
  }

  /// Photos that may auto-play in the highlights slideshow; the final-day
  /// Remembrances are deliberately kept out of it.
  List<GalleryImageItem> get _playableImages =>
      widget.images.where((i) => i.group != GalleryGroup.remembrances).toList();

  List<GalleryGroup> get _groups => GalleryGroup.values
      .where((g) => widget.images.any((i) => i.group == g))
      .toList();

  int _columnsFor(double width) => width >= 900 ? 3 : 2;

  void _openLightbox(List<GalleryImageItem> images, int index) {
    Navigator.of(context).push(
      fadeRoute(
        GalleryLightbox(
          images: images,
          initialIndex: index,
          // Unlock consent lives in the shared GalleryController, so
          // revealing a photo here unlocks it in the grid too, and vice
          // versa.
          galleryController: widget.galleryController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final images = _filtered;

    // primary must be false when a controller is supplied.
    return CustomScrollView(
      controller: widget.controller,
      primary: false,
      slivers: [
        SliverToBoxAdapter(child: _header(lang)),
        // Filter pills now come right under the title, before the
        // featured-memory card.
        SliverToBoxAdapter(child: _searchBar(lang)),
        SliverToBoxAdapter(child: _filterPills(lang)),
        // Compact featured-memory card. Hidden while the guarded Last Day
        // photos are being viewed.
        if (_playableImages.isNotEmpty &&
            _selectedGroup != GalleryGroup.remembrances)
          SliverToBoxAdapter(
            child: HeroSlideshowCard(
              images: _playableImages,
              galleryController: widget.galleryController,
              activeTab: widget.activeTab,
            ),
          ),
        SliverToBoxAdapter(child: _listHeader(lang, images.length)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: _columnsFor(MediaQuery.sizeOf(context).width),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: images.length,
            itemBuilder: (context, index) {
              final item = images[index];
              final locked =
                  item.group == GalleryGroup.remembrances &&
                  !widget.galleryController.isUnlocked(item.path);
              return _PhotoCard(
                key: ValueKey(item.path),
                item: item,
                index: index,
                locked: locked,
                onTap: () {
                  if (locked) {
                    widget.galleryController.unlock(item.path);
                  } else {
                    _openLightbox(images, index);
                  }
                },
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  /// Centered title reusing the shared Family page header design. The old
  /// trailing search button is gone (it was never wired — the working
  /// search bar sits directly below this header).
  Widget _header(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: PageTitleHeader(
        title: lang.t('nav_gallery'),
        subtitle: lang.t('gallery_subtitle'),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final GalleryImageItem item;
  final int index;
  final bool locked;
  final VoidCallback onTap;

  // A single shared Tween. TweenAnimationBuilder decides whether to
  // restart an animation by comparing the *identity* of the tween it was
  // given between rebuilds — a freshly-constructed `Tween(begin: 0, end: 1)`
  // inline in build() is never `==` to the previous one, so it was
  // restarting every card's entrance animation from frame zero on every
  // unrelated setState (unlocking one photo replayed the whole grid's
  // fade-in). A static field has one stable identity for the app's lifetime,
  // so it's recognized as "unchanged" and the animation isn't restarted.
  static final Tween<double> _fadeTween = Tween(begin: 0, end: 1);

  // Cycles through varied heights so the grid reads as masonry rather
  // than uniform tiles — mimics the natural variety of real photo
  // aspect ratios until/unless real image dimensions are read per file.
  static const List<double> _aspectRatios = [0.72, 1.05, 0.85, 1.2, 0.95, 0.78];
  static double _aspectRatioFor(int index) =>
      _aspectRatios[index % _aspectRatios.length];

  const _PhotoCard({
    super.key,
    required this.item,
    required this.index,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return TweenAnimationBuilder<double>(
      tween: _fadeTween,
      duration: const Duration(milliseconds: 600),
      curve: Interval((index % 8) * 0.07, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - v)),
          child: child,
        ),
      ),
      child: Semantics(
        button: true,
        label: locked
            ? lang.t('gallery_tap_to_reveal')
            : lang.t(item.group.key),
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: _aspectRatioFor(index),
            child: Hero(
              tag: 'gallery_${item.path}',
              child: OrnamentalCard(
                clipBehavior: Clip.antiAlias,
                radius: 16,
                borderColor: AppColors.gold,
                borderAlpha: 0.18,
                borderWidth: 0.6,
                shadowOpacity: 0.10,
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
                    TweenAnimationBuilder<double>(
                      // Blur breathing 10 -> 0 on unlock, so the photo eases
                      // into focus rather than snapping. `end` genuinely
                      // depends on `locked`, so this tween can't be const —
                      // but that's fine, its identity is *meant* to change
                      // exactly when `locked` changes.
                      tween: Tween(begin: 0, end: locked ? 10 : 0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, sigma, child) => ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: sigma,
                          sigmaY: sigma,
                        ),
                        child: child,
                      ),
                      child: Image.asset(
                        item.path,
                        fit: BoxFit.cover,
                        cacheWidth: ImageDecode.width(400, context),
                        filterQuality: FilterQuality.high,
                        errorBuilder: (c, e, s) => Container(
                          color: AppColors.cream,
                          child: const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: AppColors.muted,
                          ),
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
                            AppColors.viewerBackground.withValues(alpha: 0.65),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                    if (locked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            // Warm golden veil instead of a grey one.
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.glowGold.withValues(alpha: 0.22),
                                AppColors.gold.withValues(alpha: 0.52),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.paper.withValues(
                                    alpha: 0.92,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  // A small flame — the same candle that waits
                                  // behind the Last Day gate.
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: AppColors.amber,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                lang.t('gallery_tap_to_reveal'),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.paper,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.viewerBackground,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!locked)
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
                                  Icons.calendar_today_rounded,
                                  size: 9,
                                  color: AppColors.goldLight,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lang.t(item.date ?? 'date_1'),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.paper,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          color: AppColors.viewerBackground,
                                          blurRadius: 4,
                                        ),
                                      ],
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

