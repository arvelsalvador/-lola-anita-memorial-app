import 'package:flutter/material.dart';
import 'package:nita/utils/Constants/app_constants.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.rose,
        title: const Text('Favorites', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _FavoritesSection(
            icon: Icons.spa_rounded,
            title: 'Hobbies',
            items: const [
              'Gardening',
              'Cooking traditional dishes',
              'Sewing',
              'Attending church',
              'Storytelling with grandchildren',
            ],
          ),
          const SizedBox(height: 32),
          _FavoritesSection(
            icon: Icons.music_note_rounded,
            title: 'Music',
            items: const ['Kundiman classics', 'Religious hymns', 'Folk songs'],
          ),
          const SizedBox(height: 32),
          _FavoritesSection(
            icon: Icons.tv_rounded,
            title: 'TV Shows',
            items: const [
              'Maalaala Mo Kaya',
              'Eat Bulaga',
              'Kapuso Mo, Jessica Soho',
            ],
          ),
          const SizedBox(height: 32),
          _FavoritesSection(
            icon: Icons.favorite_rounded,
            title: 'More',
            items: const [
              'Warm coffee in the morning',
              'Family reunions',
              'Sunsets in the province',
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  const _FavoritesSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.rose, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.warmDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 7, color: AppColors.rose),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.warmDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
