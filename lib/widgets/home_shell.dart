import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/responsive.dart';
import 'package:nita/views/gallery_page.dart';
import 'package:nita/views/memories_page.dart';
import 'package:nita/views/story_page.dart';
import 'package:nita/views/tribute_page.dart';
import 'package:nita/views/favorites_page.dart';
import 'package:nita/widgets/hero_header.dart';
import 'package:nita/widgets/bottom_nav.dart';

class HomeShell extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const HomeShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Whether the page content is scrolled back to the very top. The hero
  // collapses to zero height as soon as the content scrolls at all, and stays
  // hidden while scrolling — it only expands again at the very top, so it
  // never pops back in mid-scroll.
  bool _atTop = true;

  bool _handleScrollNotification(ScrollNotification notification) {
    // This listener sits inside the NestedScrollView body, so it only sees
    // notifications from the page scrollables below it (the outer header
    // scrollable's notifications bubble up the other way).
    if (notification is ScrollUpdateNotification) {
      final atTop = notification.metrics.pixels <= 1.0;
      if (atTop != _atTop) {
        setState(() => _atTop = atTop);
      }
    }
    return false;
  }

  static final List<Widget> _bodies = [
    const StoryPage(),
    const GalleryPage(),
    const MemoriesPage(),
    const TributePage(),
    const FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final expandedHeight = (screenHeight * 0.46).clamp(400.0, 540.0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Slim brand bar (logo + language toggle) that stays fixed at the
          // top while the hero below scrolls away.
          const _TopBar(),
          Expanded(
            child: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, _) {
                    return [
                      // The hero collapses to zero height as soon as the page
                      // content scrolls (see _handleScrollNotification) and
                      // only expands again at the very top, so it never pops
                      // back in mid-scroll. The hero keeps its full height via
                      // OverflowBox and is clipped, so the portrait never
                      // squishes during the collapse animation.
                      SliverToBoxAdapter(
                        child: ClipRect(
                          child: AnimatedContainer(
                            key: const ValueKey('hero-collapse'),
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: _atTop ? expandedHeight : 0,
                            color: AppColors.warmDark,
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              maxHeight: expandedHeight,
                              child: const LolaHeroHeader(),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.contentMaxWidth(context),
                          ),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: _handleScrollNotification,
                            child: IndexedStack(
                              index: widget.selectedTab,
                              children: _bodies,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating bottom navigation.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: AppBottomNav(
                        selectedIndex: widget.selectedTab,
                        onTap: widget.onTabChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim fixed top bar: leaf logo + "nanay anita" on the left, language
/// toggle on the right, with a thin gold divider underneath. Stays at the
/// top while the hero section scrolls away.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1713),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco,
                      size: 22,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'nanay anita',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.goldLight,
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                      ),
                    ),
                    const Spacer(),
                    const _LanguageToggle(),
                  ],
                ),
              ),
            ),
            // Thin gold divider between the brand bar and the hero.
            Container(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const _LanguageSheet(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!lang.isBicol) ...[
                Text(
                  lang.isEnglish ? '🇬🇧' : '🇵🇭',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                lang.isEnglish ? 'EN' : (lang.isTagalog ? 'TL' : 'BC'),
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFFAF0E6),
                  fontWeight: lang.isBicol ? FontWeight.w400 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 14, color: Color(0xFFFAF0E6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('settings_language'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _LangOption(
            flag: '🇵🇭',
            label: 'Tagalog',
            selected: lang.isTagalog,
            onTap: () {
              lang.setLanguage(AppLanguage.tagalog);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _LangOption(
            flag: 'BC',
            label: 'Bicol',
            selected: lang.isBicol,
            onTap: () {
              lang.setLanguage(AppLanguage.bicol);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _LangOption(
            flag: '🇬🇧',
            label: 'English',
            selected: lang.isEnglish,
            onTap: () {
              lang.setLanguage(AppLanguage.english);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlainCode = flag.runes.every((r) => r < 0x1F000);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseLight : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.rose : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(
                fontSize: isPlainCode ? 15 : 24,
                letterSpacing: isPlainCode ? 0.5 : 0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.rose, size: 20),
          ],
        ),
      ),
    );
  }
}
