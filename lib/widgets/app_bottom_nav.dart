import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/ornamental_card.dart';

/// Floating bottom navigation with the five tab entries.
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'nav_home'),
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'nav_gallery'),
    (Icons.people_alt_outlined, Icons.people_alt_rounded, 'nav_family'),
    (Icons.favorite_outline_rounded, Icons.favorite_rounded, 'nav_tribute'),
    (Icons.star_border_rounded, Icons.star_rounded, 'nav_favorites'),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return OrnamentalCard(
      radius: 32,
      borderColor: AppColors.rose,
      borderAlpha: 0.15,
      borderWidth: 0.5,
      shadowOpacity: 0.12,
      shadowBlur: 24,
      shadowOffset: const Offset(0, 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.rose : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? _items[i].$2 : _items[i].$1,
                      color: active ? Colors.white : AppColors.muted,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.t(_items[i].$3),
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.5,
                        color: active ? Colors.white : AppColors.muted,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
