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

    return CustomScrollView(
      controller: controller,
      primary: false,
      physics: const ClampingScrollPhysics(),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.rose,
        borderAlpha: 0.12,
        borderWidth: 0.5,
        shadowOpacity: 0,
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: AppTextStyles.bodyText,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < memories.length; i++) ...[
          _StaggeredEntry(
            key: ValueKey(memories[i].id),
            index: i,
            child: MemoryCard(memory: memories[i], index: i),
          ),
          if (i != memories.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Botanical spray above a memory card's title — the approved design
/// (Memories_design.png) trimmed to its artwork band
/// (Memories_design_trim.png, 2002x492, no transparent padding). The
/// original canvas is 2304x1536 with the spray occupying only a quarter
/// of its height, which rendered it tiny; the trim lets BoxFit.contain
/// scale the spray to the full text-column width (tall as the width
/// allows, 35–48px on phones).
/// Vertical budget (worst case: 2-line title + 6-line body): 48px accent
/// box + 4px gap + 42px title + 6px gap + 108px body = 208px, inside the
/// 210.6px available (244px card, 16px vertical padding, 1.4px border).
class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  static const _assetPath =
      'assets/images/Editing images/Memories_design_trim.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          _assetPath,
          height: 48,
          fit: BoxFit.contain,
          // Width-axis budget: the spray is far wider than tall, so
          // width is the limiting axis. (Height-only starved it.)
          cacheWidth: ImageDecode.width(
            MediaQuery.sizeOf(context).width,
            context,
          ),
          // The spray is purely decorative — never let an asset problem
          // break the card's layout.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Memory card with a full-bleed photo occupying roughly a third of the
/// card, flush against one rounded edge — left on even-indexed cards,
/// right on odd-indexed ones, so the list reads as an alternating column
/// rather than a repeating row. A small gold accent, the title row, and
/// the body fill the remaining space. The whole card is tappable to open
/// the gallery.
class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final int index;

  const MemoryCard({super.key, required this.memory, required this.index});

  static const double _cardHeight = 244;
  static const double _photoWidth = 150;
  static const _radius = 18.0;

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

    // The photo holds its usual share of the card on normal widths but
    // yields ground on narrow phones, so the text side keeps enough room
    // for the title row's bookmark icon and the copy. Sits at the full 150px from
    // ~390px screens up; the 96px floor keeps a visible photo strip on
    // very narrow viewports.
    final photoWidth = math.max(
      96.0,
      math.min(_photoWidth, (MediaQuery.sizeOf(context).width - 40) * 0.44),
    );

    // The photo is the card's only tap target — it opens a full-screen
    // preview. The rest of the card (title, body) is static text; the
    // gallery is reached from the section header instead.
    final photo = _Pressable(
      borderRadius: photoRadius,
      onTap: () =>
          _openMemoryPhotoPreview(context, memory: memory, heroTag: heroTag),
      child: Hero(
        tag: heroTag,
        child: _MemoryPhoto(
          assetPath: memory.image,
          width: photoWidth,
          height: _cardHeight,
          borderRadius: photoRadius,
        ),
      ),
    );

    final content = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _TitleAccent(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang.t(memory.titleKey),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayHeading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.bookmark_border_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // The body is summarized to fit ~6 lines on the card's text
            // column (12px caption, 1.5 line height) at typical phone
            // widths — no trailing ellipsis. The no-ellipsis probe test
            // in test/memory_card_overflow_test.dart enforces this.
            Text(
              lang.t(memory.bodyKey),
              textAlign: TextAlign.justify,
              style: AppTextStyles.caption,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    return Container(
      height: _cardHeight,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: photoOnLeft ? [photo, content] : [content, photo],
      ),
    );
  }
}

/// The photo content for a memory's photo slot: the memory's own bundled
/// asset when one is wired in ([assetPath], from MemoryItem.image), the
/// soft gradient placeholder when it isn't. Shared by the card thumbnail
/// and the full-screen preview so the Hero flight lands on exactly the
/// same picture the thumbnail showed, at whatever size the destination
/// needs.
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
  final double iconSize;

  const _MemoryPhoto({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return _PhotoPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
        iconSize: iconSize,
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
        // Height-axis budget (not width): the card/preview slots are
        // taller than they are wide while the photos are mostly
        // landscape, so height is the cover-limiting axis. A width-only
        // budget starves it (~2x upscale blur); decoding both axes
        // would squash the aspect (exact-fill), so height-only it is.
        cacheHeight: ImageDecode.height(height, context),
        errorBuilder: (context, error, stackTrace) => _PhotoPlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
          iconSize: iconSize,
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
class _MemoryPhotoPreview extends StatelessWidget {
  final MemoryItem memory;
  final String heroTag;
  const _MemoryPhotoPreview({required this.memory, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).width * 0.86;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: heroTag,
                  child: _MemoryPhoto(
                    assetPath: memory.image,
                    width: side,
                    height: side,
                    borderRadius: BorderRadius.circular(20),
                    iconSize: 64,
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
/// divider, and an italic attribution.
class QuoteCard extends StatelessWidget {
  final String quote, attribution;
  const QuoteCard({super.key, required this.quote, required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
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
              fontFamily: 'Lora',
              fontSize: 40,
              color: AppColors.gold,
              height: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyItalic,
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
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Timeline (story section) --
/// Vertical timeline of life events: year rail with dot markers (a leaf
/// medallion on the first event) and the event title + description.
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: markerColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // First event gets a larger "medallion" marker with a
                    // leaf icon, matching the reference design. Every
                    // other event keeps the original small dot.
                    if (isFirst)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: markerColor,
                          border: Border.all(color: AppColors.cream, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: AppColors.paper,
                        ),
                      )
                    else
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
                        style: AppTextStyles.displayHeading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.t(e.descriptionKey),
                        textAlign: TextAlign.justify,
                        style: AppTextStyles.caption,
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

