import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/navigation.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/models/gallery_group.dart';
import 'package:nita/widgets/circle_icon_button.dart';
import 'package:nita/widgets/floating_close_button.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/photo_counter_pill.dart';
import 'package:nita/widgets/stagger_entrance.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Shared top overlay for full-screen photo viewers: a close button
/// (top-right) and a "current / total" counter pill (top-left).
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
                  color: Colors.white,
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
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final ScrollController? controller;

  /// Reports the active tab index from the home shell. When the value
  /// becomes the gallery tab (1), the "featured" glow state resets.
  final ValueNotifier<int>? activeTab;

  /// Created by the home shell (composition root) and injected here — the
  /// view never constructs or owns the controller.
  final GalleryController galleryController;

  const GalleryPage({
    super.key,
    this.controller,
    this.activeTab,
    required this.galleryController,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _didInit = false;
  bool _didPrecache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      widget.galleryController.addListener(_onChanged);
      widget.galleryController.load();
    }
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_didPrecache) _precacheFeatured();
  }

  @override
  void dispose() {
    widget.galleryController.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _precacheFeatured() async {
    if (_didPrecache) return;
    _didPrecache = true;
    final images = widget.galleryController.images;
    if (images == null) return;
    final count = math.min(images.length, 9);
    await Future.wait([
      for (int i = 0; i < count; i++)
        precacheImage(AssetImage(images[i].path), context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final images = widget.galleryController.images;

    if (images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (images.isEmpty) {
      return Center(
        child: Text(
          lang.t('no_images'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GalleryGridView(
      images: images,
      controller: widget.controller,
      activeTab: widget.activeTab,
      galleryController: widget.galleryController,
    );
  }
}

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

  // --- Auto-slideshow for hero card ---
  int _heroIndex = 0;
  Timer? _heroTimer;

  /// Compact, side-by-side "featured memory" card: square thumbnail on the
  /// left, label + date in the middle, a round play button on the right.
  Widget _heroCard(LanguageProvider lang) {
    if (_playableImages.isEmpty) return const SizedBox.shrink();
    final item = _playableImages[_heroIndex];

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
              final shuffled = List<GalleryImageItem>.of(_playableImages)
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBE1D3), width: 1),
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
                              color: Color(0xFFB0653A),
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
                                fontFamily: 'Georgia',
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
                        color: Color(0xFFB0653A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.white,
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
    final count = _playableImages.length;
    final backItem = count > 2
        ? _playableImages[(_heroIndex + 2) % count]
        : null;
    final midItem = count > 1
        ? _playableImages[(_heroIndex + 1) % count]
        : null;

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
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
                cacheWidth: 200,
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
                      color: Color(0xFFB0653A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.white,
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

  Widget _searchBar(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0D6CC), width: 1),
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
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white,
                  Colors.white,
                  // No fade at all once there's nothing left to scroll
                  // to — the gradient becomes fully opaque white,
                  // meaning BlendMode.dstIn changes nothing.
                  _pillsCanScrollMore ? Colors.transparent : Colors.white,
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
                    color: Color(0xFFB0653A),
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
        : AppColors.white;
    final unselectedBorder = isRemembrances
        ? AppColors.gold
        : const Color(0xFFE0D6CC);
    final unselectedTextColor = isRemembrances
        ? const Color(0xFFB06A2B)
        : AppColors.warmDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFB0653A) : unselectedBg,
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
                  color: selected ? AppColors.white : unselectedTextColor,
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
                  color: selected ? AppColors.white : unselectedTextColor,
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
  Widget _listHeader(LanguageProvider lang, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.t('gallery_all_photos_label'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.warmDark,
            ),
          ),
          Text(
            '$count ${lang.t('gallery_photos')}',
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
    // No shell to report visibility -> assume always visible (e.g. previews/tests).
    if (widget.activeTab == null || widget.activeTab!.value == 1) {
      _startHeroTimer();
    }
  }

  void _updatePillsFade() {
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

  void _onTabChanged() {
    // The gallery is tab index 1 in the home shell.
    final isVisible = widget.activeTab?.value == 1;
    if (isVisible) {
      _startHeroTimer();
      if (_visited.isNotEmpty) setState(_visited.clear);
    } else {
      _heroTimer?.cancel();
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_playableImages.isEmpty) return;
      setState(() {
        _heroIndex = (_heroIndex + 1) % _playableImages.length;
      });
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    widget.activeTab?.removeListener(_onTabChanged);
    _searchController.dispose();
    _pillsScrollController.dispose();
    super.dispose();
  }

  List<GalleryImageItem> get _filtered {
    // "All" deliberately excludes Remembrances — those locked photos only
    // appear once the visitor explicitly taps that category (and passes
    // the candle gate), not mixed anonymously into the general grid.
    final byGroup = _selectedGroup == null
        ? widget.images
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
          SliverToBoxAdapter(child: _heroCard(lang)),
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

  /// Title row with a trailing search button, and a small subtitle below.
  Widget _header(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lang.t('nav_gallery'),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmDark,
                  ),
                ),
              ),
              CircleIconButton(
                icon: Icons.search_rounded,
                onTap: () {
                  // TODO: wire up gallery search.
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lang.t('gallery_subtitle'),
            style: const TextStyle(fontSize: 13, color: AppColors.warmMid),
          ),
        ],
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
                    if (locked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            // Warm golden veil instead of a grey one.
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFF7E7B6).withValues(alpha: 0.22),
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
                                  color: AppColors.white.withValues(
                                    alpha: 0.92,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  // A small flame — the same candle that waits
                                  // behind the Last Day gate.
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: Color(0xFFB06A2B),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                lang.t('gallery_tap_to_reveal'),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
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
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
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
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

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
    final item = widget.images[_current];

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.images.length,
            itemBuilder: (context, i) {
              final image = widget.images[i];
              final locked = _isLocked(i);
              final viewer = InteractiveViewer(
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
                            const Color(0xFFF7E7B6).withValues(alpha: 0.16),
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
                              color: AppColors.white.withValues(alpha: 0.92),
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
                              color: Color(0xFFB06A2B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.t('gallery_tap_to_reveal'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFF6E0),
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
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppColors.white,
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

/// Full-screen solemn moment shown before the Remembrances photos.
///
/// The visitor finds a candle waiting beneath her portrait; tapping anywhere
/// lights the flame, a warm light blooms over the scene, and after a short
/// pause the page fades back so the gallery can reveal the photos. Pops with
/// `true` once lit.
class CandleGate extends StatefulWidget {
  final int photoCount;

  const CandleGate({super.key, required this.photoCount});

  @override
  State<CandleGate> createState() => _CandleGateState();
}

class _CandleGateState extends State<CandleGate> with TickerProviderStateMixin {
  static const _portraitAsset = AppAssets.nanayPortrait;

  // Phase offsets so the flame, the portrait's "breathing," and the hand's
  // bob don't all move in perfect lockstep off the same _flicker value.
  // Without these, everything pulses together and reads as mechanical
  // instead of alive.
  static const double _portraitPhaseOffset = 0.37;
  static const double _handPhaseOffset = 0.71;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  // The pointing hand and its "Please tap" text drift on a slower rhythm
  // than the flame, so the invitation feels calm instead of jittery.
  late final AnimationController _handBob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Wraps _bloom in an easing curve so the warm light feels like it's
  // catching and flaring, rather than growing at a flat, linear rate.
  late final Animation<double> _bloomCurve = CurvedAnimation(
    parent: _bloom,
    curve: Curves.easeOutCubic,
  );

  bool _lit = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _entrance.dispose();
    _flicker.dispose();
    _handBob.dispose();
    _bloom.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _lightCandle() {
    if (_lit) return;
    HapticFeedback.lightImpact(); // gentle tactile confirmation the candle caught
    setState(() => _lit = true);
    _bloom.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: Semantics(
        button: true,
        label: lang.t('remembrance_gate_label'),
        hint: lang.t('remembrance_gate_subtitle'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _lightCandle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 1.0,
                    colors: const [
                      Color(0xFF322217),
                      Color(0xFF1B120B),
                      Color(0xFF0D0805),
                    ],
                  ),
                ),
              ),
              // Warm light that blooms over the whole scene once lit.
              AnimatedBuilder(
                animation: _bloomCurve,
                builder: (context, _) => IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.12),
                        radius: 1.05,
                        colors: [
                          const Color(
                            0xFFFFC96A,
                          ).withValues(alpha: 0.4 * _bloomCurve.value),
                          const Color(
                            0xFFFFC96A,
                          ).withValues(alpha: 0.12 * _bloomCurve.value),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.0,
                        end: 0.4,
                        offset: const Offset(0, -6),
                        child: _gateLabel(lang),
                      ),
                      const SizedBox(height: 18),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.15,
                        end: 0.5,
                        child: _PortraitMedallion(
                          asset: _portraitAsset,
                          lit: _lit,
                          flicker: _flicker,
                          bloom: _bloomCurve,
                          phaseOffset: _portraitPhaseOffset,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.3,
                        end: 0.62,
                        offset: const Offset(0, 10),
                        child: Text(
                          lang.t('remembrance_gate_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.45,
                        end: 0.75,
                        offset: const Offset(0, 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Text(
                            _lit
                                ? lang.t('remembrance_gate_lit')
                                : lang.t('remembrance_gate_subtitle'),
                            key: ValueKey(_lit),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _lit
                                  ? AppColors.goldLight
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.2,
                        end: 0.7,
                        offset: const Offset(0, 34),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: 150,
                          height: 188,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              RepaintBoundary(
                                child: SizedBox(
                                  width: 150,
                                  height: 188,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _flicker,
                                      _bloomCurve,
                                    ]),
                                    builder: (context, _) {
                                      // Two overlapping sine waves at different
                                      // speeds instead of one clean wave — this
                                      // is what makes the flame's sway look
                                      // organic instead of metronomic.
                                      final wobble =
                                          math.sin(
                                                _flicker.value * 2 * math.pi,
                                              ) *
                                              0.7 +
                                          math.sin(
                                                _flicker.value * 5 * math.pi +
                                                    1.1,
                                              ) *
                                              0.3;
                                      return CustomPaint(
                                        painter: _CandlePainter(
                                          lit: _lit,
                                          bloom: _bloomCurve.value,
                                          flicker: wobble,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // A pointing hand above the candle, gently
                              // bobbing, invites the tap. It fades away once
                              // the flame is lit.
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _lit
                                    ? const SizedBox.shrink(
                                        key: ValueKey('lit'),
                                      )
                                    : SizedBox(
                                        key: const ValueKey('unlit'),
                                        width: 150,
                                        height: 188,
                                        child: AnimatedBuilder(
                                          animation: _handBob,
                                          builder: (context, _) {
                                            final bob = math.sin(
                                              (_handBob.value +
                                                      _handPhaseOffset) *
                                                  2 *
                                                  math.pi,
                                            );
                                            final pulse =
                                                0.6 + 0.4 * (0.5 + 0.5 * bob);
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Transform.translate(
                                                  // Upper-right, farther from
                                                  // the candle, finger aimed
                                                  // down-left toward the wick.
                                                  offset: Offset(
                                                    40,
                                                    -34 + bob * 4,
                                                  ),
                                                  child: Transform.rotate(
                                                    angle: -2.4,
                                                    child: const Icon(
                                                      Icons
                                                          .pan_tool_alt_rounded,
                                                      size: 30,
                                                      color:
                                                          AppColors.goldLight,
                                                    ),
                                                  ),
                                                ),
                                                // Gentle pulsing plea right
                                                // beside the hand.
                                                Transform.translate(
                                                  offset: Offset(
                                                    48,
                                                    -56 + bob * 2,
                                                  ),
                                                  child: Opacity(
                                                    opacity: pulse,
                                                    child: Text(
                                                      lang.t(
                                                        'remembrance_gate_please_tap',
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontFamily: 'Georgia',
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.goldLight,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggerEntrance(
                        controller: _entrance,
                        begin: 0.6,
                        end: 0.9,
                        offset: const Offset(0, 8),
                        child: Column(
                          children: [
                            Text(
                              '${widget.photoCount} ${lang.t('gallery_photos')}'
                              '${lang.t('remembrance_gate_held')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.4,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _lit
                                  ? lang.t('remembrance_gate_waiting')
                                  : lang.t('remembrance_gate_tap_hint'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                                color: Colors.white30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: FloatingCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateLabel(LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 1.5708,
          child: const Icon(Icons.eco_rounded, size: 13, color: AppColors.gold),
        ),
        const SizedBox(width: 10),
        Text(
          lang.t('remembrance_gate_label').toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 1.5708,
          child: const Icon(Icons.eco_rounded, size: 13, color: AppColors.gold),
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 1,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

/// Gold-ringed oval portrait of Nanay. A soft halo gathers behind her once
/// the candle is lit.
class _PortraitMedallion extends StatelessWidget {
  final String asset;
  final bool lit;
  final Animation<double> flicker;
  final Animation<double> bloom;
  final double phaseOffset;

  const _PortraitMedallion({
    required this.asset,
    required this.lit,
    required this.flicker,
    required this.bloom,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([flicker, bloom]),
        builder: (context, child) {
          final breathe =
              1 + 0.015 * math.sin((flicker.value + phaseOffset) * 2 * math.pi);
          return Transform.scale(
            scale: breathe,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(
                      alpha: lit ? 0.45 * bloom.value : 0.22,
                    ),
                    AppColors.gold.withValues(
                      alpha: lit ? 0.1 * bloom.value : 0.0,
                    ),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.6),
                ),
                child: ClipOval(child: child!),
              ),
            ),
          );
        },
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: 256,
          errorBuilder: (c, e, s) => Container(
            color: AppColors.cream,
            child: const Icon(
              Icons.person_outline_rounded,
              size: 26,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Candle with wax drips on a small golden saucer. Before it is lit, a wisp
/// of smoke curls above the wick and dissolves as the flame catches; once
/// lit, the flame breathes with two layered flickers and a warm halo blooms
/// around it.
class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.lit,
    required this.bloom,
    required this.flicker,
  });

  final bool lit;
  final double bloom;
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final waxTop = size.height * 0.58;
    final waxBottom = size.height * 0.86;
    final waxWidth = size.width * 0.2;

    // Ground shadow under the saucer.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.955),
        width: waxWidth * 2.1,
        height: 9,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Golden saucer.
    final saucer = Rect.fromCenter(
      center: Offset(cx, size.height * 0.945),
      width: waxWidth * 1.85,
      height: 11,
    );
    canvas.drawOval(
      saucer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFE9D3A6), Color(0xFFB98E4F)],
        ).createShader(saucer),
    );
    canvas.drawOval(
      saucer.deflate(2),
      Paint()..color = const Color(0xFF8F6A33),
    );

    // Warm halo blooming around the flame when lit.
    if (lit) {
      final glowCenter = Offset(cx, waxTop - 26);
      final glowRadius = size.height * (0.42 + 0.04 * flicker + 0.16 * bloom);
      canvas.drawCircle(
        glowCenter,
        glowRadius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFC96A).withValues(alpha: 0.55),
                  const Color(0xFFFFC96A).withValues(alpha: 0.0),
                ],
              ).createShader(
                Rect.fromCircle(center: glowCenter, radius: glowRadius),
              ),
      );
    }

    // A wisp of smoke that fades out as the flame's bloom fades in, instead
    // of vanishing abruptly the instant the candle is lit.
    final smokeOpacity = lit ? (1 - bloom).clamp(0.0, 1.0) : 1.0;
    if (smokeOpacity > 0) {
      final smokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12 * smokeOpacity)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(cx, waxTop - 10)
        ..quadraticBezierTo(cx + 3 * flicker, waxTop - 22, cx - 2, waxTop - 32)
        ..quadraticBezierTo(
          cx - 6 * flicker.abs(),
          waxTop - 42,
          cx + 1,
          waxTop - 50,
        );
      canvas.drawPath(path, smokePaint);
    }

    // Flame: outer amber, middle gold, bright core. Two layered flickers
    // make the light feel alive.
    if (lit) {
      final flameBase = Offset(cx, waxTop - 4);
      final fh =
          size.height *
          0.17 *
          (1 + 0.04 * flicker + 0.05 * math.sin(flicker * 3 + 1.3));
      final fw = size.height * 0.075 * (1 + 0.05 * flicker);
      final outerRect = Rect.fromLTWH(
        flameBase.dx - fw,
        flameBase.dy - fh,
        fw * 2,
        fh,
      );
      canvas.drawPath(
        _flamePath(flameBase, fh, fw),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFFFD54F),
              Color(0xFFFF8F00),
              Color(0xFFFF6D00),
            ],
          ).createShader(outerRect),
      );
      canvas.drawPath(
        _flamePath(flameBase, fh * 0.62, fw * 0.58),
        Paint()..color = const Color(0xFFFFE082),
      );
      canvas.drawPath(
        _flamePath(flameBase, fh * 0.3, fw * 0.3),
        Paint()..color = const Color(0xFFFFFDE7),
      );
    }

    // Wick.
    canvas.drawLine(
      Offset(cx, waxTop - 2),
      Offset(cx, waxTop + 7),
      Paint()
        ..color = const Color(0xFF4A3626)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Wax body with a soft vertical shading.
    final waxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - waxWidth / 2, waxTop, waxWidth, waxBottom - waxTop),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      waxRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE9DEC8),
            Color(0xFFFBF6EA),
            Color(0xFFD9CBB0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(waxRect.outerRect),
    );

    // Melted rim.
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - waxWidth * 0.62, waxTop - 3, waxWidth * 1.24, 9),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(
      rimRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFFFDF8EE), Color(0xFFEDE2CC)],
        ).createShader(rimRect.outerRect),
    );

    // Wax drips hanging from the rim.
    final dripPaint = Paint()..color = const Color(0xFFF3EBD8);
    const drips = [
      (dx: 0.52, len: 0.12),
      (dx: 0.62, len: 0.07),
      (dx: 0.44, len: 0.16),
      (dx: 0.55, len: 0.05),
    ];
    for (final drip in drips) {
      final dx = cx - waxWidth / 2 + waxWidth * drip.dx;
      final h = size.height * drip.len;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx - 2.2, waxTop + 4, 4.4, h),
          const Radius.circular(2.2),
        ),
        dripPaint,
      );
    }
  }

  Path _flamePath(Offset base, double h, double w) {
    return Path()
      ..moveTo(base.dx, base.dy - h)
      ..quadraticBezierTo(base.dx + w, base.dy - h * 0.35, base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx - w,
        base.dy - h * 0.35,
        base.dx,
        base.dy - h,
      );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.lit != lit ||
      oldDelegate.bloom != bloom ||
      oldDelegate.flicker != flicker;
}

class HighlightSlideshow extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;

  /// Injected controller — the view only triggers playback; locating the
  /// bundled audio file happens in the controller.
  final GalleryController galleryController;

  const HighlightSlideshow({
    super.key,
    required this.images,
    required this.galleryController,
    this.initialIndex = 0,
  });

  @override
  State<HighlightSlideshow> createState() => _HighlightSlideshowState();
}

class _HighlightSlideshowState extends State<HighlightSlideshow> {
  static const _photoDuration = Duration(seconds: 5);

  late int _current = widget.initialIndex;
  bool _playing = true;
  bool _hasMusic = false;
  bool _muted = false;
  Timer? _timer;
  AudioPlayer? _music;

  // All bundled tracks available to pick from, and which one is
  // currently playing — powers the new music-picker bottom sheet.
  List<String> _availableTracks = [];
  String? _currentTrackPath;

  @override
  void initState() {
    super.initState();
    _initMusic();
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _music?.dispose();
    super.dispose();
  }

  Future<void> _initMusic() async {
    try {
      final tracks = await widget.galleryController.findAllAudioAssets();
      if (tracks.isEmpty) return;
      if (mounted) setState(() => _availableTracks = tracks);

      final defaultPath = await widget.galleryController.findFirstAudioAsset();
      final startPath = defaultPath ?? tracks.first;

      final player = AudioPlayer();
      _music = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.45);
      await player.play(AssetSource(startPath));
      if (mounted) {
        setState(() {
          _hasMusic = true;
          _currentTrackPath = startPath;
        });
      }
    } catch (_) {
      _music?.dispose();
    }
  }

  /// Switches background music to [path] without interrupting the photo
  /// slideshow itself — stops the current track and starts the new one
  /// at the same volume/mute state, keeping playback logic identical to
  /// what _initMusic already sets up.
  Future<void> _selectTrack(String path) async {
    if (path == _currentTrackPath || _music == null) return;
    try {
      await _music!.stop();
      await _music!.play(AssetSource(path));
      await _music!.setVolume(_muted ? 0 : 0.45);
      if (mounted) setState(() => _currentTrackPath = path);
    } catch (_) {
      // Leave the previous track playing if switching fails, rather than
      // silently killing music the visitor was already enjoying.
    }
  }

  void _showTrackPicker() {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.viewerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('gallery_choose_music'),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availableTracks.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final path = _availableTracks[index];
                      final selected = path == _currentTrackPath;
                      final title = path
                          .split('/')
                          .last
                          .replaceAll(RegExp(r'\.(mp3|wav|m4a)$'), '');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selected
                              ? Icons.play_circle_fill_rounded
                              : Icons.music_note_rounded,
                          color: selected ? AppColors.gold : Colors.white54,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: selected ? AppColors.gold : Colors.white,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.gold,
                              )
                            : null,
                        onTap: () {
                          _selectTrack(path);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(_photoDuration, () {
      if (!mounted) return;
      setState(() => _current = (_current + 1) % widget.images.length);
      _scheduleNext();
    });
  }

  void _goTo(int index) {
    setState(() {
      _current = (index + widget.images.length) % widget.images.length;
    });
    _scheduleNext();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _scheduleNext();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _music?.setVolume(_muted ? 0 : 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final item = widget.images[_current];

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeOut,
            child: _KenBurnsPhoto(
              key: ValueKey(_current),
              item: item,
              index: _current,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
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
                // Photo counter pinned to the top-left so it never sits
                // over the middle of the image.
                Positioned(
                  top: 12,
                  left: 12,
                  child: PhotoCounterPill(
                    current: _current,
                    total: widget.images.length,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(_current),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.t(item.group.key),
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lang.t(item.location ?? 'loc_lipa')}  •  '
                            '${lang.t(item.date ?? 'date_1')}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleIconButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => _goTo(_current - 1),
                        ),
                        const SizedBox(width: 14),
                        CircleIconButton(
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          filled: true,
                          onTap: _togglePlay,
                        ),
                        const SizedBox(width: 14),
                        CircleIconButton(
                          icon: Icons.skip_next_rounded,
                          onTap: () => _goTo(_current + 1),
                        ),
                        if (_hasMusic) ...[
                          const SizedBox(width: 14),
                          CircleIconButton(
                            icon: _muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            onTap: _toggleMute,
                          ),
                          if (_availableTracks.length > 1) ...[
                            const SizedBox(width: 14),
                            CircleIconButton(
                              icon: Icons.library_music_rounded,
                              onTap: _showTrackPicker,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KenBurnsPhoto extends StatefulWidget {
  final GalleryImageItem item;
  final int index;

  const _KenBurnsPhoto({super.key, required this.item, required this.index});

  @override
  State<_KenBurnsPhoto> createState() => _KenBurnsPhotoState();
}

class _KenBurnsPhotoState extends State<_KenBurnsPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: _zoomOut ? 1.14 : 1.0,
    end: _zoomOut ? 1.0 : 1.14,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<Offset> _pan = Tween<Offset>(
    begin: _panFrom,
    end: _panTo,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _zoomOut => widget.index.isOdd;

  Offset get _panFrom => switch (widget.index % 4) {
    0 => const Offset(-0.022, 0),
    1 => const Offset(0.02, 0.014),
    2 => const Offset(0, -0.022),
    _ => const Offset(-0.016, 0.016),
  };

  Offset get _panTo => switch (widget.index % 4) {
    0 => const Offset(0.022, 0),
    1 => const Offset(-0.02, -0.014),
    2 => const Offset(0, 0.022),
    _ => const Offset(0.016, -0.016),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FractionalTranslation(
        translation: _pan.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Image.asset(
        widget.item.path,
        fit: BoxFit.cover,
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
        errorBuilder: (c, e, s) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}
