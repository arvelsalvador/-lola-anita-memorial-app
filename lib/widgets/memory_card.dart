import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/memories_model.dart';

class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  const MemoryCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final icon = _iconForMemory(memory.titleKey);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.12),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.roseLight,
                  AppColors.goldLight.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Center(child: Icon(icon, size: 20, color: AppColors.rose)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t(memory.titleKey),
                  style: AppTextStyles.serifHeading,
                ),
                const SizedBox(height: 4),
                Text(lang.t(memory.bodyKey), style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForMemory(String key) {
    return switch (key) {
      'memory_1_title' => Icons.restaurant_rounded,
      'memory_2_title' => Icons.church_rounded,
      'memory_3_title' => Icons.content_cut_rounded,
      'memory_4_title' => Icons.local_florist_rounded,
      'memory_5_title' => Icons.music_note_rounded,
      'memory_6_title' => Icons.mail_rounded,
      _ => Icons.favorite_rounded,
    };
  }
}
