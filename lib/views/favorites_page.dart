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
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: AppColors.gold.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  lang.t('nav_favorites'),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(
                builder: (context, constraints) {
                  final sections = [
                    _FavoritesSection(
                      icon: Icons.spa_rounded,
                      title: lang.t('section_hobbies'),
                      items: const [
                        'fav_hobby_1',
                        'fav_hobby_2',
                        'fav_hobby_3',
                        'fav_hobby_4',
                        'fav_hobby_5',
                      ],
                    ),
                    _FavoritesSection(
                      icon: Icons.music_note_rounded,
                      title: lang.t('section_music'),
                      items: const [
                        'fav_music_1',
                        'fav_music_2',
                        'fav_music_3',
                      ],
                    ),
                    _FavoritesSection(
                      icon: Icons.tv_rounded,
                      title: lang.t('section_tv_shows'),
                      items: const ['fav_tv_1', 'fav_tv_2', 'fav_tv_3'],
                    ),
                    _FavoritesSection(
                      icon: Icons.favorite_rounded,
                      title: lang.t('section_more'),
                      items: const ['fav_more_1', 'fav_more_2', 'fav_more_3'],
                    ),
                  ];

                  if (constraints.maxWidth < 620) {
                    return Column(
                      children: [
                        for (int i = 0; i < sections.length; i++) ...[
                          sections[i],
                          if (i != sections.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: sections
                        .map(
                          (section) => SizedBox(
                            width: (constraints.maxWidth - 14) / 2,
                            child: section,
                          ),
                        )
                        .toList(),
                  );
                },
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
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.18),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.roseLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.rose, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warmDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: AppColors.gold.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      lang.t(item),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.warmDeep,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
