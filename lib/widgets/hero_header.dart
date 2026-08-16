import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';

/// Full-bleed memorial header.
///
/// The image already contains the name, portrait, and memorial dates.
/// It is presented as a keepsake portrait: rounded bottom corners, a thin
/// gold outer frame, a gold matting line inset from the edges, and a soft
/// shadow falling into the cream page below.
class LolaHeroHeader extends StatelessWidget {
  const LolaHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmDark.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22.5),
              ),
              child: Image.asset(
                'assets/images/backgroundIMG.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.warmMid,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_florist,
                      size: 64,
                      color: Color(0xFFFAF0E6),
                    ),
                  );
                },
              ),
            ),
          ),
          // Inner matting line, inset like a picture-frame mat.
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
