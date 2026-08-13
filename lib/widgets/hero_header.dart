import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

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
            color: AppColors.gold.withValues(alpha: 0.6),
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
            color: Colors.black.withValues(alpha: 0.4),
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
        child: ClipOval(
          child: Image.asset(
            'assets/images/gallery/Nanay_dp.png',
            fit: BoxFit.cover,
            width: 104,
            height: 104,
            errorBuilder: (context, error, stackTrace) => Center(
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
        ),
      ),
    );
  }
}
