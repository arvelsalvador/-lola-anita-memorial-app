import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/tribute_model.dart';

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
            color: AppColors.warmDark.withValues(alpha: 0.4),
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
            color: AppColors.gold.withValues(alpha: 0.5),
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

class FamilyQuoteCard extends StatelessWidget {
  final FamilyQuote quote;
  const FamilyQuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 0.5),
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

class CandleSection extends StatefulWidget {
  const CandleSection({super.key});

  @override
  State<CandleSection> createState() => _CandleSectionState();
}

class _CandleSectionState extends State<CandleSection> {
  int _localCount = 124;
  bool _lit = false;
  bool _loading = false;

  Future<void> _lightCandle() async {
    if (_lit) return;
    setState(() {
      _loading = true;
      _lit = true;
      _localCount++;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('memorial').doc('anita_lumbao');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          transaction.set(docRef, {'candleCount': _localCount});
        } else {
          final current = snapshot.data()?['candleCount'] ?? 124;
          transaction.update(docRef, {'candleCount': current + 1});
        }
      });
    } catch (_) {
      // Fallback to local optimistic count
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Text(_lit ? '🔥' : '🕯️', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            _lit ? 'Candle Lit in Her Memory' : lang.t('candle_light'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              color: AppColors.warmDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          StreamBuilder<DocumentSnapshot>(
            stream: (() {
              try {
                return FirebaseFirestore.instance.collection('memorial').doc('anita_lumbao').snapshots();
              } catch (_) {
                return const Stream<DocumentSnapshot?>.empty() as Stream<DocumentSnapshot>;
              }
            })(),
            builder: (context, snapshot) {
              int count = _localCount;
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data['candleCount'] != null) {
                  count = data['candleCount'] as int;
                }
              }
              return Text(
                '$count ${lang.t('candle_virtual')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warmMid,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _lit || _loading ? null : _lightCandle,
            style: ElevatedButton.styleFrom(
              backgroundColor: _lit ? AppColors.gold : AppColors.warmDark,
              foregroundColor: const Color(0xFFFAF0E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              _lit ? '🕊️ Thank You' : lang.t('candle_light'),
              style: const TextStyle(fontSize: 13, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
