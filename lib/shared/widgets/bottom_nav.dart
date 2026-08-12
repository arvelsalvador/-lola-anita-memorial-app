import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/responsive.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isMobile = Responsive.isMobile(context);

    final items = [
      (Icons.home_outlined, Icons.home_rounded, lang.t('nav_home')),
      (Icons.photo_library_outlined, Icons.photo_library_rounded, lang.t('nav_gallery')),
      (Icons.auto_stories_outlined, Icons.auto_stories_rounded, lang.t('nav_memories')),
      (Icons.favorite_outline_rounded, Icons.favorite_rounded, lang.t('nav_tribute')),
      (Icons.star_border_rounded, Icons.star_rounded, lang.t('nav_favorites')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.rose.withOpacity(0.15), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].$2,
                          color: active ? AppColors.rose : AppColors.muted,
                          size: isMobile ? 20 : 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: isMobile ? 8 : 9,
                            letterSpacing: 0.5,
                            color: active ? AppColors.rose : AppColors.muted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: active ? 4 : 0,
                          height: active ? 4 : 0,
                          decoration: const BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
