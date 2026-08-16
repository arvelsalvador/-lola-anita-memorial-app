import 'dart:ui' show ImageFilter;

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

class HomeShell extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const HomeShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

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
    final expandedHeight = (screenHeight * 0.92).clamp(520.0, 700.0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: expandedHeight,
                  backgroundColor: AppColors.warmDark,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  clipBehavior: Clip.hardEdge,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        const LolaHeroHeader(),
                        // Frosted-glass overlay: blurs the photo and whatever
                        // content has scrolled under the header once collapsed.
                        AnimatedOpacity(
                          opacity: innerBoxIsScrolled ? 1 : 0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                color: AppColors.cream.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(child: _LanguageToggle()),
                    ),
                  ],
                ),
                // Gold hairline that fades in beneath the collapsed header.
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    opacity: innerBoxIsScrolled ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.55),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.contentMaxWidth(context),
                    ),
                    child: IndexedStack(index: selectedTab, children: _bodies),
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
                  selectedIndex: selectedTab,
                  onTap: onTabChanged,
                ),
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(20),
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
