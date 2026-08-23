import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/widgets/ornament_divider.dart';

/// Serif quote card with a large opening quotation mark, an ornament
/// divider, and an italic attribution.
class QuoteCard extends StatelessWidget {
  final String quote, attribution;
  const QuoteCard({super.key, required this.quote, required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        children: [
          Text(
            '\u201C',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 40,
              color: AppColors.gold,
              height: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: AppTextStyles.serifItalic,
          ),
          const SizedBox(height: 16),
          const OrnamentDivider(
            lineLength: 24,
            lineAlpha: 0.4,
            gap: 8,
            center: OrnamentCenter.dot,
          ),
          const SizedBox(height: 10),
          Text(
            attribution,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
