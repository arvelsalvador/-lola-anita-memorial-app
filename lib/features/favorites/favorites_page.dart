import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              lang.t('nav_favorites'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _FavoritesSection(
                icon: Icons.spa_rounded,
                title: lang.t('section_hobbies'),
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
                title: lang.t('section_music'),
                items: const ['Kundiman classics', 'Religious hymns', 'Folk songs'],
              ),
              const SizedBox(height: 32),
              _FavoritesSection(
                icon: Icons.tv_rounded,
                title: lang.t('section_tv_shows'),
                items: const [
                  'Maalaala Mo Kaya',
                  'Eat Bulaga',
                  'Kapuso Mo, Jessica Soho',
                ],
              ),
              const SizedBox(height: 32),
              _FavoritesSection(
                icon: Icons.favorite_rounded,
                title: lang.t('section_more'),
                items: const [
                  'Warm coffee in the morning',
                  'Family reunions',
                  'Sunsets in the province',
                ],
              ),
            ]),
          ),
        ),
      ],
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
