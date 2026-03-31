import 'package:flutter/material.dart';
import 'package:nita/utils/Constants/app_constants.dart';
import 'package:nita/Widgets/shared_widgets.dart';
import 'package:nita/Pages/Story/View/story_page.dart';
import 'package:nita/Pages/Gallery/View/gallery_page.dart';
import 'package:nita/Pages/Memories/View/memories_page.dart';
import 'package:nita/Pages/Tributes/View/tribute_page.dart';
import 'package:nita/Pages/Favorites/favorites_page.dart';

/// Wraps each tab page with the shared hero header + a scrollable body.
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
    StoryPage(),
    GalleryPage(),
    MemoriesPage(),
    TributePage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverToBoxAdapter(
            child: LolaHeroHeader(
              name: name,
              initial: initial,
              years: years,
              tagline: tagline,
            ),
          ),
        ],
        body: IndexedStack(index: selectedTab, children: _bodies),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedTab,
        onTap: onTabChanged,
      ),
    );
  }
}
