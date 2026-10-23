part of 'home_page.dart';

/// The Story tab (Home tab index 0): her words, her journey, about her,
/// and the cherished memories section.
class StoryPage extends StatelessWidget {
  final ScrollController? controller;

  /// Called when the visitor taps anything that points at the gallery
  /// ("Tingnan sa Galeri", "Buksan ang mga larawan"). The home shell uses
  /// it to switch to the gallery tab.
  final VoidCallback? onOpenGallery;

  final HomeController homeController;

  const StoryPage({
    super.key,
    this.controller,
    this.onOpenGallery,
    required this.homeController,
  });

  @override
  Widget build(BuildContext context) {
    const data = HomeController.data;
    final lang = context.watch<LanguageProvider>();
    final locked = context.watch<GuideController?>()?.inputLocked ?? false;

    return CustomScrollView(
      controller: controller,
      primary: false,
      physics: locked
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ScrollReveal(
                id: 'label-her-words',
                index: 0,
                child: SectionLabel(lang.t('section_her_words')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'quote-card',
                index: 1,
                child: QuoteCard(
                  quote: lang.t(data.quoteKey),
                  attribution: lang.t(data.quoteAttributionKey),
                ),
              ),
              const SizedBox(height: 28),
              _ScrollReveal(
                id: 'label-her-journey',
                index: 2,
                child: SectionLabel(lang.t('section_her_journey')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'timeline',
                index: 3,
                child: TimelineWidget(events: data.timeline),
              ),
              const SizedBox(height: 28),
              _ScrollReveal(
                id: 'label-about-her',
                index: 4,
                child: SectionLabel(lang.t('section_about_her')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'about-card',
                index: 5,
                child: AboutCard(
                  text: lang.t(data.aboutKey),
                  onTap: onOpenGallery,
                ),
              ),
              const SizedBox(height: 32),
              _ScrollReveal(
                id: 'label-cherished-memories',
                index: 6,
                child: SectionLabel(lang.t('section_cherished_memories')),
              ),
              const SizedBox(height: 12),
              _ScrollReveal(
                id: 'memories-section',
                index: 7,
                floatUp: true,
                child: MemoriesSection(homeController: homeController),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Simple white card with the "about her" story text.
class AboutCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const AboutCard({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: OrnamentalCard(
        radius: 12,
        borderColor: AppColors.rose,
        borderAlpha: 0.12,
        borderWidth: 0.5,
        shadowOpacity: 0,
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          // Justified on every card. The card component supplies enough
          // width that the word gaps stay natural on phones.
          textAlign: TextAlign.justify,
          style: AppTextStyles.homeContent.copyWith(
            color: AppColors.warmMid,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}

/// The cherished-memories block: the memory cards. Lives on the home page
/// (the Story tab). The old filter pill row (Lahat / Buhay / Pamilya /
/// Pagdiriwang) was removed — the categories were redundant with the
/// gallery's own filters, and with them gone the "Lahat" pill had nothing
/// left to filter.
class MemoriesSection extends StatefulWidget {
  final HomeController homeController;

  const MemoriesSection({super.key, required this.homeController});

  @override
  State<MemoriesSection> createState() => _MemoriesSectionState();
}

class _MemoriesSectionState extends State<MemoriesSection> {
  @override
  void initState() {
    super.initState();
    widget.homeController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.homeController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final memories = HomeController.memoriesData.memories;
    final lang = context.watch<LanguageProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        final photoWidth = (cardWidth * 0.38).roundToDouble();
        final textColumnWidth = cardWidth - photoWidth - 32;

        final textScaler = MediaQuery.textScalerOf(context).clamp(
          maxScaleFactor: 1.4,
        );

        double maxContentHeight = 0;
        for (final memory in memories) {
          final h = MemoryCard.measureContentHeight(
            title: lang.t(memory.titleKey),
            body: lang.t(memory.bodyKey),
            textWidth: textColumnWidth,
            textScaler: textScaler,
          );
          if (h > maxContentHeight) {
            maxContentHeight = h;
          }
        }

        final cardHeight = math.max(
          276.0,
          (maxContentHeight + 56.0).ceilToDouble(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < memories.length; i++) ...[
              _StaggeredEntry(
                key: ValueKey(memories[i].id),
                index: i,
                child: MemoryCard(
                  memory: memories[i],
                  index: i,
                  cardHeight: cardHeight,
                  photoWidth: photoWidth,
                ),
              ),
              if (i != memories.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

/// Botanical spray decoration for memory cards — trimmed artwork
/// band (900x221), sized to ~90px wide with ~0.9 opacity and warm gold tint.
/// Positioned in the outer top corner on the text side of the card,
/// mirrored horizontally on alternating cards.
class _TitleAccent extends StatelessWidget {
  final bool mirrored;
  const _TitleAccent({this.mirrored = false});

  static const _assetPath =
      'assets/images/editing_images/Memories_design_trim.png';

  /// Trimmed artwork ratio (900x221).
  static const double _aspectRatio = 900 / 221;
  static const double _width = 90.0;
  static const double _height = _width / _aspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget image = ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFFC9A25E),
        BlendMode.srcIn,
      ),
      child: Image.asset(
        _assetPath,
        width: _width,
        height: _height,
        fit: BoxFit.contain,
        cacheWidth: ImageDecode.width(_width, context),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );

    if (mirrored) {
      image = Transform.flip(
        flipX: true,
        child: image,
      );
    }

    return Opacity(
      opacity: 0.9,
      child: SizedBox(
        width: _width,
        height: _height,
        child: image,
      ),
    );
  }
}

/// Expand badge overlaid on a memory card's photo: a small dark pill
/// with a magnifier glyph that tells visitors the photo is tappable.
/// Decorative only (the photo's own tap handles the press), so it lives
/// inside an [IgnorePointer] at the call site.
class _ExpandBadge extends StatelessWidget {
  const _ExpandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.zoom_in_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

/// Memory card with a full-bleed photo occupying roughly 38% of the
/// card, flush against one rounded edge — left on even-indexed cards,
/// right on odd-indexed ones, so the list reads as an alternating column
/// rather than a repeating row. A warm gold botanical accent, the title row,
/// and the body fill the remaining space. All cards share the same height
/// and photo dimensions, with copy vertically centered.
class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final int index;
  final double? cardHeight;
  final double? photoWidth;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.index,
    this.cardHeight,
    this.photoWidth,
  });

  static const _radius = 12.0;

  static double measureContentHeight({
    required String title,
    required String body,
    required double textWidth,
    required TextScaler textScaler,
  }) {
    if (textWidth <= 0) return 0;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: AppTextStyles.memoryCardTitle,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: textWidth);

    final bodyPainter = TextPainter(
      text: TextSpan(
        text: body,
        style: AppTextStyles.homeContent.copyWith(
          color: AppColors.muted,
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: textWidth);

    final bodyHeight = bodyPainter.size.height + 18.0;
    return titlePainter.size.height + 6 + 3 + 10 + bodyHeight;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final photoOnLeft = index.isEven;
    // Unique per card, needed so Hero can match this thumbnail to the
    // right full-screen preview when several cards are on screen.
    final heroTag = 'memory-photo-${memory.id}';
    final photoRadius = BorderRadius.horizontal(
      left: photoOnLeft ? const Radius.circular(_radius) : Radius.zero,
      right: photoOnLeft ? Radius.zero : const Radius.circular(_radius),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        final effectivePhotoWidth =
            photoWidth ?? (cardWidth * 0.38).roundToDouble();
        final textColumnWidth = cardWidth - effectivePhotoWidth - 32;

        final textScaler = MediaQuery.textScalerOf(context).clamp(
          maxScaleFactor: 1.4,
        );

        final double effectiveCardHeight;
        if (cardHeight != null) {
          effectiveCardHeight = cardHeight!;
        } else {
          final contentH = measureContentHeight(
            title: lang.t(memory.titleKey),
            body: lang.t(memory.bodyKey),
            textWidth: textColumnWidth,
            textScaler: textScaler,
          );
          effectiveCardHeight = math.max(
            276.0,
            (contentH + 56.0).ceilToDouble(),
          );
        }

        // The photo is the card's only tap target — it opens a full-screen
        // preview. The rest of the card (title, body) is static text; the
        // gallery is reached from the section header instead. The expand
        // badge overlaid on the photo tells visitors it is tappable.
        final photo = Semantics(
          button: true,
          label: lang.t('memory_photo_hint'),
          child: _Pressable(
            borderRadius: photoRadius,
            onTap: () => _openMemoryPhotoPreview(
              context,
              memory: memory,
              heroTag: heroTag,
            ),
            child: Stack(
              // The slot is sized tightly by its Positioned parent in the card,
              // so expand forces the photo to fill the card's full height.
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag,
                  child: _MemoryPhoto(
                    assetPath: memory.image,
                    width: effectivePhotoWidth,
                    height: effectiveCardHeight,
                    borderRadius: photoRadius,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: photoOnLeft ? 8 : null,
                  right: photoOnLeft ? null : 8,
                  child: const IgnorePointer(
                    child: _ExpandBadge(),
                  ),
                ),
              ],
            ),
          ),
        );

        final content = MediaQuery.withClampedTextScaling(
          // Elderly visitors run large accessibility font sizes; cap the
          // on-card text so it still grows with the OS setting but stays
          // readable instead of ballooning the card unpredictably.
          maxScaleFactor: 1.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Stretch so the title's TextAlign.center centres across the
            // whole column (an intrinsically sized Text would sit at the
            // start even with textAlign.center).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carved serif heading: dark, centred.
              Text(
                lang.t(memory.titleKey),
                textAlign: TextAlign.center,
                style: AppTextStyles.memoryCardTitle,
              ),
              const SizedBox(height: 6),
              // Short gold rule beneath the title (~6px above, ~10px below).
              Center(
                child: Container(
                  key: const ValueKey('memory-title-rule'),
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Body text at 12sp with 1.5 line height.
              BalancedJustifyText(
                lang.t(memory.bodyKey),
                textAlign: TextAlign.left,
                style: AppTextStyles.homeContent.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );

        return Container(
          height: effectiveCardHeight,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: AppColors.rose.withValues(alpha: 0.14),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Pinned to both vertical edges so the photo fills the entire card height.
              Positioned(
                top: 0,
                bottom: 0,
                left: photoOnLeft ? 0 : null,
                right: photoOnLeft ? null : 0,
                width: effectivePhotoWidth,
                child: photo,
              ),
              // Line-art flower decoration in the top outer corner on the
              // text side of the card, mirrored on alternating cards.
              // Kept behind the text (lower in the stack) and wrapped in IgnorePointer.
              Positioned(
                top: 4,
                left: photoOnLeft ? null : 8,
                right: photoOnLeft ? 8 : null,
                child: IgnorePointer(
                  child: _TitleAccent(mirrored: !photoOnLeft),
                ),
              ),
              // Vertically centered text column.
              Positioned(
                top: 0,
                bottom: 0,
                left: photoOnLeft ? (effectivePhotoWidth + 16) : 16,
                right: photoOnLeft ? 16 : (effectivePhotoWidth + 16),
                child: Center(
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The photo content for a memory card's photo slot: the memory's own
/// bundled asset when one is wired in ([assetPath], from MemoryItem.image),
/// the soft gradient placeholder when it isn't. The full-screen preview
/// lays the same asset out with [BoxFit.contain] instead (no crop).
///
/// A missing asset must never take the layout down with it: the default
/// load-failure widget is an unwrapped error string that overflows this
/// fixed-size slot (the "RIGHT OVERFLOWED BY 104 PIXELS" seen when the
/// Best Pictures folder wasn't bundled), so load failures fall back to
/// the placeholder.
class _MemoryPhoto extends StatelessWidget {
  final String? assetPath;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _MemoryPhoto({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return _PhotoPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        // Height-axis budget (not width): the card slots are taller than
        // they are wide while the photos are mostly landscape, so height
        // is the cover-limiting axis. A width-only budget starves it
        // (~2x upscale blur); decoding both axes would squash the aspect
        // (exact-fill), so height-only it is.
        cacheHeight: ImageDecode.height(height, context),
        errorBuilder: (context, error, stackTrace) => _PhotoPlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Placeholder for a memory's photo — a soft rose/gold gradient block with
/// an image icon, standing in until real photos are wired in. Used directly
/// by [_MemoryPhoto], which wraps the wired-in assets and falls back to
/// this placeholder when an asset is missing. The sizing, clipping, and
/// alternating placement in MemoryCard stay the same.
class _PhotoPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double iconSize;

  const _PhotoPlaceholder({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.rose.withValues(alpha: 0.45),
              AppColors.gold.withValues(alpha: 0.45),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.paper.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Opens a full-screen preview of a memory's photo. This is intentionally
/// separate from the card's own onTap (which opens the gallery tab) — the
/// photo has its own destination, not the gallery.
void _openMemoryPhotoPreview(
  BuildContext context, {
  required MemoryItem memory,
  required String heroTag,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _MemoryPhotoPreview(memory: memory, heroTag: heroTag),
        );
      },
    ),
  );
}

/// Full-screen photo viewer. Shares a Hero tag with the thumbnail in
/// MemoryCard, so the photo grows smoothly from its card position into
/// the full-screen view instead of just cross-fading in. Tap anywhere,
/// or the close button, to dismiss.
///
/// The photo keeps its own aspect ratio inside the screen: the destination
/// used to be a square with [BoxFit.cover], which cut portrait photos off
/// at the top/bottom (and landscape ones at the sides). It now fits the
/// whole photo inside the available box with [BoxFit.contain].
class _MemoryPhotoPreview extends StatelessWidget {
  final MemoryItem memory;
  final String heroTag;
  const _MemoryPhotoPreview({required this.memory, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Leave room for the close button and breathing space around the photo.
    final maxWidth = screen.width * 0.92;
    final maxHeight = screen.height * 0.78;
    final path = memory.image;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  child: Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: path == null
                          ? _PhotoPlaceholder(
                              width: maxWidth,
                              height: maxWidth,
                              borderRadius: BorderRadius.circular(12),
                              iconSize: 64,
                            )
                          : Image.asset(
                              path,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              // Width-axis budget: the image is laid out at
                              // its aspect-correct size inside the box above,
                              // so a width decode covers both orientations
                              // without squashing the aspect (the old
                              // square trick did that).
                              cacheWidth: ImageDecode.width(maxWidth, context),
                              errorBuilder: (context, error, stackTrace) =>
                                  _PhotoPlaceholder(
                                    width: maxWidth,
                                    height: maxWidth,
                                    borderRadius: BorderRadius.circular(12),
                                    iconSize: 64,
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared micro-interaction widgets, private to this file.
// ---------------------------------------------------------------------

// -- Quote card (story section) --
/// Serif quote card with a large opening quotation mark, an ornament
/// divider, and an attribution in the homepage content voice.
class QuoteCard extends StatelessWidget {
  final String quote, attribution;
  const QuoteCard({super.key, required this.quote, required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        children: [
          const Text(
            '\u201C',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              color: AppColors.gold,
              height: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeContent.copyWith(
              color: AppColors.textDark,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 16),
          const OrnamentDivider(
            lineLength: 24,
            lineAlpha: 0.4,
            gap: 8,
            center: OrnamentCenter.dot,
          ),
          const SizedBox(height: 10),
          Text(
            attribution,
            style: AppTextStyles.homeContent.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// -- Timeline (story section) --
/// Vertical timeline of life events: year rail with dot markers
/// and the event title + description.
class TimelineWidget extends StatelessWidget {
  final List<LifeEvent> events;
  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isFirst = i == 0;
        final isLast = i == events.length - 1;
        final markerColor = e.isLast ? AppColors.gold : AppColors.rose;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(
                      e.year,
                      style: AppTextStyles.homeContent.copyWith(
                        color: markerColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Every event uses the same small dot marker.
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markerColor,
                        border: Border.all(color: AppColors.cream, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: markerColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.rose.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 20,
                    top: isFirst ? 6 : 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t(e.titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeContent.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.t(e.descriptionKey),
                        textAlign: TextAlign.left,
                        style: AppTextStyles.homeContent.copyWith(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
