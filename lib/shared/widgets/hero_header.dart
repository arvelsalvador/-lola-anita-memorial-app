import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/responsive.dart';

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
    final topPad = Responsive.heroHeaderPaddingTop(context);
    final horizontalPad = Responsive.isMobile(context) ? 20.0 : 24.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.warmDark, AppColors.warmDeep],
        ),
      ),
      padding: EdgeInsets.fromLTRB(horizontalPad, topPad, horizontalPad, 28),
      child: Column(
        children: [
          PortraitRing(initial: initial),
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

class PortraitRing extends StatelessWidget {
  final String initial;
  const PortraitRing({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    final size = Responsive.isMobile(context) ? 100.0 : 120.0;

    return Container(
      width: size,
      height: size,
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
        child: ClipOval(
          child: Image.asset(
            'assets/images/gallery/Nanay_dp.png',
            fit: BoxFit.cover,
            width: size - 6,
            height: size - 6,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: size * 0.36,
                  color: const Color(0xFFFAF0E6),
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
