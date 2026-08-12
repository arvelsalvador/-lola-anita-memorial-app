import 'package:flutter/material.dart';
import 'package:nita/Pages/Tributes/Model/tribute_model.dart';
import 'package:nita/Utils/Constants/app_constants.dart';

// ── Main Tribute Card ─────────────────────────────────────────────────────────
class TributeMainCard extends StatelessWidget {
  final String message;
  const TributeMainCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.warmDark, AppColors.warmDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text(
            'Until we meet again',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Color(0xFFFAF0E6),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'IN LOVING MEMORY',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.gold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 50,
            height: 0.8,
            color: AppColors.gold.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: Color(0xFFD4BFB5),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family Quote Card ─────────────────────────────────────────────────────────
class FamilyQuoteCard extends StatelessWidget {
  final FamilyQuote quote;
  const FamilyQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201C${quote.quote}\u201D',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: AppColors.warmMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${quote.name}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Candle Section ────────────────────────────────────────────────────────────
class CandleSection extends StatelessWidget {
  const CandleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Text('🕯️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            'Light a candle',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              color: AppColors.warmDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'In honor of Lola Remedios',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warmMid,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmDark,
              foregroundColor: const Color(0xFFFAF0E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Light a candle',
              style: TextStyle(fontSize: 13, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
