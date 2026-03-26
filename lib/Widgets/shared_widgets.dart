import 'package:flutter/material.dart';
import 'package:nita/utils/Constants/app_constants.dart';

// ── Section Label ─────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTextStyles.sectionLabel);
}

// ── Lola Hero Header ──────────────────────────────────────────────────────────
class LolaHeroHeader extends StatelessWidget {
  final String name, initial, years, tagline;
  const LolaHeroHeader({
    super.key,
    required this.name,
    required this.initial,
    required this.years,
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.warmDark, AppColors.warmDeep],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        children: [
          _PortraitRing(initial: initial),
          const SizedBox(height: 16),
          Text(name, style: AppTextStyles.serifDisplay),
          const SizedBox(height: 4),
          Text(years, style: AppTextStyles.goldYears),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 0.8,
            color: AppColors.gold.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            tagline,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Color(0xFFD4BFB5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitRing extends StatelessWidget {
  final String initial;
  const _PortraitRing({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFC4956A), Color(0xFF7A4E3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 44,
              color: Color(0xFFFAF0E6),
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Gallery'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Memories'),
    (Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Tribute'),
  ];

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[i].$2,
                        color: active ? AppColors.rose : AppColors.muted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].$3,
                        style: TextStyle(
                          fontSize: 9,
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
              );
            }),
          ),
        ),
      ),
    );
  }
}
