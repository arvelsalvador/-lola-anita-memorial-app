import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

/// Floating bottom navigation with the five tab entries.
///
/// Cleaner modern look: light paper shell with a hairline gold border,
/// Lora tab labels, and a small gold indicator under the active tab
/// instead of the old solid rose fill pill.
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
    (Icons.format_quote_outlined, Icons.format_quote_rounded, 'nav_words'),
    (
      Icons.local_fire_department_outlined,
      Icons.local_fire_department_rounded,
      'nav_condolences',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = selectedIndex == i;
          return Expanded(
            child: Semantics(
              button: true,
              selected: active,
              label: lang.t(_items[i].$3),
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                // 48px min tap target for elderly visitors.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.roseDeep.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? _items[i].$2 : _items[i].$1,
                          color: active
                              ? AppColors.roseDeep
                              : AppColors.muted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.t(_items[i].$3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 10,
                            color: active
                                ? AppColors.roseDeep
                                : AppColors.muted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: active ? 16 : 4,
                          height: 3,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.gold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
