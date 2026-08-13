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
  final String name, initial, years, tagline;

  const HomeShell({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.name,
    required this.initial,
    required this.years,
    required this.tagline,
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 310,
                backgroundColor: AppColors.warmDark,
                elevation: 2,
                flexibleSpace: FlexibleSpaceBar(
                  background: LolaHeroHeader(
                    name: name,
                    initial: initial,
                    years: years,
                    tagline: tagline,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      color: Color(0xFFFAF0E6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Center(child: _LanguageToggle()),
                  ),
                ],
              ),
            ],
            body: SafeArea(
              top: false,
              child: SizedBox.expand(
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
              Text(
                lang.isEnglish ? '🇬🇧' : '🇵🇭',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                lang.isEnglish ? 'EN' : 'TL',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFAF0E6),
                  fontWeight: FontWeight.w600,
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
            flag: '🇬🇧',
            label: 'English',
            selected: lang.isEnglish,
            onTap: () {
              lang.setLanguage(AppLanguage.english);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _LangOption(
            flag: '🇵🇭',
            label: 'Tagalog',
            selected: lang.isTagalog,
            onTap: () {
              lang.setLanguage(AppLanguage.tagalog);
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
            Text(flag, style: const TextStyle(fontSize: 24)),
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
