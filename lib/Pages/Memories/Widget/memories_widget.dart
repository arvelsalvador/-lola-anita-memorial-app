import 'package:flutter/material.dart';
import 'package:nita/Pages/Memories/Model/memories_model.dart';
import 'package:nita/Utils/Constants/app_constants.dart';

class MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  const MemoryCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: AppColors.rose, width: 3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.roseLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(memory.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.title, style: AppTextStyles.serifHeading),
                const SizedBox(height: 4),
                Text(memory.body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
