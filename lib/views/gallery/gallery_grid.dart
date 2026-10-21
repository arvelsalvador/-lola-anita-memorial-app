part of 'gallery_page.dart';

class GalleryGridView extends StatefulWidget {
  final List<GalleryImageItem> images;
  final ScrollController? controller;
  final ValueNotifier<int>? activeTab;

  /// Bumped by the shell's top-bar `?` to replay the Gallery tour. Auto-open
  /// on first visit still runs through [activeTab]; this only re-opens a tour
  /// the visitor has already seen or skipped.
  final ValueListenable<int>? guideRequests;

  final GalleryController galleryController;
  const GalleryGridView({
    super.key,
    required this.images,
    this.controller,
    this.activeTab,
    this.guideRequests,
    required this.galleryController,
  });

  @override
  State<GalleryGridView> createState() => _GalleryGridViewState();
}

class _GalleryGridViewState extends State<GalleryGridView> {
  GalleryGroup? _selectedGroup;
  // Search text the visitor typed. Empty string = no search filter.
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Global rect source for the Gallery guide: the lit bar is the real one.
  final GlobalKey _searchBarKey = GlobalKey();

  /// Global rect source for the guide's second stop, the filter-pill row.
  final GlobalKey _filterPillsKey = GlobalKey();

  /// Global rect source for the gold Huling Araw pill the second stop names.
  final GlobalKey _hulingArawKey = GlobalKey();

  /// Published to the guide once the pill row has slid the gold pill into
  /// view, so it can ring it inside the lit row. Null until measured.
  final ValueNotifier<Rect?> _hulingArawRect = ValueNotifier<Rect?>(null);

  /// Global rect source for the guide's third stop, the featured slideshow
  /// card. Attached to the card's surface, inside its own padding, so the
  /// hole hugs the card rather than the whole sliver slot.
  final GlobalKey _featuredCardKey = GlobalKey();

  /// Published to the guide so the third stop's hole can appear once the
  /// card has been scrolled on screen (short viewports).
  final ValueNotifier<Rect?> _featuredCardRect = ValueNotifier<Rect?>(null);

  /// One-shot guard so the guide is scheduled at most once per grid instance.
  bool _galleryGuideCheckStarted = false;

  // Tracks whether the filter-pill row can still scroll further right,
  // so the edge fade only shows when it's actually true — not as a
  // permanent decoration that lingers even at the end of the list.
  final ScrollController _pillsScrollController = ScrollController();
  bool _pillsCanScrollMore = false;

  // Featured-memory rotation lives in [HeroSlideshowCard] so its 5s timer
  // never rebuilds this grid state.

  Widget _searchBar(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        key: _searchBarKey,
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
          // Taller than the pills themselves so Inter's descenders
          // (the tails of "g" in "Pagdiriwang") are never clipped by
          // the horizontal ListView's edge.
          SizedBox(
            key: _filterPillsKey,
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
                      // Measured for the guide's second stop, which rings
                      // this pill once the row has slid it into view.
                      key: group == GalleryGroup.remembrances
                          ? _hulingArawKey
                          : null,
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
    Key? key,
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
      key: key,
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
    _pillsScrollController.addListener(_updatePillsFade);
    widget.activeTab?.addListener(_onActiveTabChanged);
    widget.guideRequests?.addListener(_onGuideRequested);
    // Check once after the first frame, in case there are enough pills
    // to overflow even before the user touches the row.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePillsFade());
    // The grid can mount after the Gallery tab is already active (the image
    // manifest may finish loading late), so try once on the first frame too.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowGalleryGuide(),
    );
    // One fixed shuffle order per page instance: the "Lahat na Larawan"
    // grid shows the photos in a mixed-up order instead of the sorted
    // source order. Built once in initState so the grid doesn't reshuffle
    // on filter/search setStates.
    _shuffleRandom = math.Random();
  }

  @override
  void didUpdateWidget(covariant GalleryGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.activeTab, widget.activeTab)) {
      oldWidget.activeTab?.removeListener(_onActiveTabChanged);
      widget.activeTab?.addListener(_onActiveTabChanged);
    }
    if (!identical(oldWidget.guideRequests, widget.guideRequests)) {
      oldWidget.guideRequests?.removeListener(_onGuideRequested);
      widget.guideRequests?.addListener(_onGuideRequested);
    }
  }

  /// Gallery lives inside the home shell's IndexedStack, so it is mounted
  /// before the visitor ever opens the tab. The tab notifier is the real
  /// "opened Gallery" signal.
  void _onActiveTabChanged() {
    if (widget.activeTab?.value == 1) _maybeShowGalleryGuide();
  }

  /// The top-bar `?` asked for the tour again. Unlike the first-visit path
  /// this ignores the "seen" flag — the button is an explicit request.
  void _onGuideRequested() {
    _maybeShowGalleryGuide(replay: true);
  }

  void _maybeShowGalleryGuide({bool replay = false}) {
    if (!replay && _galleryGuideCheckStarted) return;
    if (widget.activeTab?.value != 1) return;
    _galleryGuideCheckStarted = true;

    // The next frame has the tab laid out (and, in the shell, the scroll
    // reset queued). `_openGalleryGuide` still re-checks the rect and brings
    // the bar back if the grid was scrolled down.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openGalleryGuide(replay: replay),
    );
    // The notifier listener can fire outside a frame (as in tests), so make
    // sure the callback above actually gets a frame to run at.
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _openGalleryGuide({bool replay = false}) async {
    if (!mounted || widget.activeTab?.value != 1) {
      if (!replay) _galleryGuideCheckStarted = false;
      return;
    }

    if (!replay) {
      final seen = await const GuideRepository.gallery().hasSeen();
      if (!mounted || seen || widget.activeTab?.value != 1) return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      // Another overlay is on top (for example the homepage guide is still
      // fading out). Let the visitor re-enter the tab to try again.
      if (!replay) _galleryGuideCheckStarted = false;
      return;
    }

    final rect = _paddedControlRect(_searchBarKey, h: 6, v: 4);
    if (rect == null) {
      // The search bar is the first stop, so it has to be on screen before
      // the tour opens: scroll the grid back to the top, then measure again
      // once the jump has been laid out (a few frames at most).
      final barContext = _searchBarKey.currentContext;
      if (barContext != null && barContext.mounted) {
        // Back to the top of the page, so the tour starts on the same view a
        // first-time visitor sees (header, search bar, then the pills).
        final scrollable = Scrollable.maybeOf(barContext);
        if (scrollable != null) {
          scrollable.position.jumpTo(scrollable.position.minScrollExtent);
        } else {
          Scrollable.ensureVisible(
            barContext,
            alignment: 0,
            duration: Duration.zero,
          );
        }
      }
      _pushGalleryGuideWhenVisible(replay: replay);
      return;
    }

    _pushGalleryGuide(rect);
  }

  /// Waits for the search bar to be laid out on screen after the scroll, then
  /// opens the tour on it. Gives up after a few frames rather than pushing a
  /// guide with a hole in the wrong place.
  void _pushGalleryGuideWhenVisible({required bool replay, int attempts = 3}) {
    if (!mounted) return;
    final rect = _paddedControlRect(_searchBarKey, h: 6, v: 4);
    if (rect != null) {
      _pushGalleryGuide(rect);
      return;
    }
    if (attempts <= 0) {
      // Still not laid out (tab fade, first frame): let a later visit try
      // again instead of leaving the one-shot flag stuck on.
      if (!replay) _galleryGuideCheckStarted = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pushGalleryGuideWhenVisible(replay: replay, attempts: attempts - 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// A spotlighted control's global rect, or null when it is not laid out or
  /// not on screen — so the scrim never cuts a hole in the wrong place.
  Rect? _controlRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.top < 0 || rect.bottom > screen.height) return null;
    return rect;
  }

  Rect? _paddedControlRect(GlobalKey key, {double h = 6, double v = 4}) {
    final raw = _controlRect(key);
    if (raw == null) return null;
    return Rect.fromLTRB(
      raw.left - h,
      raw.top - v,
      raw.right + h,
      raw.bottom + v,
    );
  }

  void _pushGalleryGuide(Rect searchBarRect) {
    if (!mounted) return;
    // Measure now: on phones and desktop the card is already on screen with
    // room for the bubble, so the third stop opens with its hole in place
    // instead of flashing the full-screen fallback while it waits for a
    // scroll.
    _featuredCardRect.value = _featuredRectOnScreen(_featuredCardKey);
    Navigator.of(context)
        .push(
          fadeRoute(
            GuidePage(
              tour: GuideTour.gallery,
              searchBarRect: searchBarRect,
              // Null if the row is below the fold; the second stop then falls
              // back to a full-screen scrim instead of a misplaced hole.
              filterPillsRect: _paddedControlRect(_filterPillsKey, h: 8, v: 4),
              onFilterPillsShown: _revealFilterPills,
              hulingArawRect: _hulingArawRect,
              onFeaturedCardShown: _revealFeaturedCard,
              featuredCardRect: _featuredCardRect,
            ),
            opaque: false,
          ),
        )
        .then((_) => _resetFilterPillsScroll());
  }

  /// Returns the filter-pill row to its default start alignment so "Huling
  /// Araw" stays at the end until the visitor scrolls sideways themselves.
  void _resetFilterPillsScroll() {
    if (!mounted || !_pillsScrollController.hasClients) return;
    if (_pillsScrollController.position.pixels != 0) {
      _pillsScrollController.jumpTo(0);
    }
  }

  /// Vertical room the guide bubble needs under a lit control. A card lower
  /// than this is scrolled to the top of the grid so its copy still fits.
  static const double _bubbleRoom = 200;

  /// Like [_controlRect], but also null when there is not enough room left
  /// under the control for the guide bubble — the third stop then shows the
  /// full-screen fallback until the card has been scrolled up.
  Rect? _featuredRectOnScreen(GlobalKey key) {
    final rect = _paddedControlRect(key, h: 6, v: 5);
    if (rect == null) return null;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return rect.bottom + _bubbleRoom <= screenHeight ? rect : null;
  }

  /// Slides the pill row to the end when the guide reaches its second stop,
  /// so the gold Huling Araw pill is actually visible under the cut-out
  /// instead of sitting off-screen. Only the row scrolls, so the measured
  /// screen rect (and therefore the hole) stays correct.
  void _revealFilterPills() {
    // The search and pill holes are measured with the page at the top. If
    // the featured stop scrolled the grid (short viewports), jump back first
    // so the row is where the hole expects it.
    final pillsContext = _filterPillsKey.currentContext;
    final page = pillsContext == null
        ? null
        : Scrollable.maybeOf(pillsContext);
    if (page != null && page.position.pixels > page.position.minScrollExtent) {
      page.position.jumpTo(page.position.minScrollExtent);
    }
    final controller = _pillsScrollController;
    if (!controller.hasClients) {
      _publishHulingArawRect();
      return;
    }
    // A lazy ListView only estimates its full extent until the far end has
    // been laid out. After the first slide, ease back to the real end if the
    // estimate overshot, so the row never rests in blank trailing space.
    controller
        .animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted || !controller.hasClients) return;
          final max = controller.position.maxScrollExtent;
          if (controller.position.pixels > max + 0.5) {
            controller
                .animateTo(
                  max,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                )
                .then((_) => _publishHulingArawRect());
            return;
          }
          _publishHulingArawRect();
        });
  }

  /// Tells the guide where the gold pill ended up, so it can ring it inside
  /// the lit row. Measured after the row's slide has been laid out — a rect
  /// taken mid-animation would point at the wrong pill.
  void _publishHulingArawRect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hulingArawRect.value = _controlRect(_hulingArawKey);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Brings the featured card fully on screen for the third stop. On phones
  /// it already is, so nothing moves; on short/landscape viewports the grid
  /// scrolls it up, then the hole follows the measured position.
  void _revealFeaturedCard() {
    final cardContext = _featuredCardKey.currentContext;
    if (cardContext == null || !cardContext.mounted) {
      _publishFeaturedCardRect();
      return;
    }
    // Already fully visible with room for the bubble: the push-time rect is
    // still right and moving the page would be a needless jolt.
    if (_featuredRectOnScreen(_featuredCardKey) != null) {
      _publishFeaturedCardRect();
      return;
    }
    Scrollable.ensureVisible(
      cardContext,
      alignment: 0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    ).then((_) => _publishFeaturedCardRect());
  }

  void _publishFeaturedCardRect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _featuredCardRect.value = _featuredRectOnScreen(_featuredCardKey);
    });
    WidgetsBinding.instance.scheduleFrame();
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

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onActiveTabChanged);
    widget.guideRequests?.removeListener(_onGuideRequested);
    _hulingArawRect.dispose();
    _featuredCardRect.dispose();
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
              surfaceKey: _featuredCardKey,
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
                      builder: (context, sigma, child) =>
                          // ImageFiltered forcibly allocates a saveLayer
                          // every frame — once the blur has settled at
                          // sigma 0 there is nothing left to draw, so
                          // drop the wrapper and render the plain image
                          // (its natural sharp rendering) instead.
                          sigma > 0
                          ? ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: sigma,
                                sigmaY: sigma,
                              ),
                              child: child,
                            )
                          : child!,
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
