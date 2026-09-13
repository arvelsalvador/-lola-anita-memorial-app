import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nita/models/tribute_model.dart';

class TributeController extends ChangeNotifier {
  static const TributeModel data = TributeModel(
    tributeMessageKey: 'tribute_message',
    featuredQuote: FamilyQuote(
      quoteKey: 'words_featured_quote',
      nameKey: 'words_featured_name',
      relationKey: 'words_featured_relation',
      group: QuoteGroup.children,
      dateKey: 'words_date_1',
    ),
    familyQuotes: [
      // ── Mga anak (children) ────────────────────────────────────────────
      FamilyQuote(
        quoteKey: 'words_quote_1',
        nameKey: 'words_quote_1_name',
        relationKey: 'words_relation_bunso',
        group: QuoteGroup.children,
        dateKey: 'words_date_1',
        photoPath: 'assets/images/Family DP/lorie.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_2',
        nameKey: 'words_quote_2_name',
        relationKey: 'words_relation_panganay',
        group: QuoteGroup.children,
        dateKey: 'words_date_2',
        photoPath: 'assets/images/Family DP/gernan.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_3',
        nameKey: 'words_quote_3_name',
        relationKey: 'words_relation_ikalawa',
        group: QuoteGroup.children,
        dateKey: 'words_date_3',
        photoPath: 'assets/images/Family DP/Odin.jpg',
      ),
      // ── Mga kapatid (siblings) ────────────────────────────────────────
      FamilyQuote(
        quoteKey: 'words_quote_4',
        nameKey: 'words_quote_4_name',
        relationKey: 'words_relation_kapatid_lalaki',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_4',
        photoPath: 'assets/images/Family DP/obit.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_5',
        nameKey: 'words_quote_5_name',
        relationKey: 'words_relation_kapatid_lalaki',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_5',
        photoPath: 'assets/images/Family DP/dolfo.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_6',
        nameKey: 'words_quote_6_name',
        relationKey: 'words_relation_kapatid_babae',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_6',
        photoPath: 'assets/images/Family DP/sonia.jpg',
      ),
      // ── Mga apo (grandchildren) ───────────────────────────────────────
      FamilyQuote(
        quoteKey: 'words_quote_7',
        nameKey: 'words_quote_7_name',
        relationKey: 'words_relation_apo_babae',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_7',
        photoPath: 'assets/images/Family DP/hans.png',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_8',
        nameKey: 'words_quote_8_name',
        relationKey: 'words_relation_apo_babae',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_8',
        photoPath: 'assets/images/Family DP/audrey.png',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_9',
        nameKey: 'words_quote_9_name',
        relationKey: 'words_relation_apo_lalaki',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_9',
        photoPath: 'assets/images/Family DP/rodel.png',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_10',
        nameKey: 'words_quote_10_name',
        relationKey: 'words_relation_apo_babae',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_10',
        photoPath: 'assets/images/Family DP/Rose-ann.png',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_11',
        nameKey: 'words_quote_11_name',
        relationKey: 'words_relation_apo_lalaki',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_11',
        photoPath: 'assets/images/Family DP/arvel.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_12',
        nameKey: 'words_quote_12_name',
        relationKey: 'words_relation_apo_lalaki',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_12',
        photoPath: 'assets/images/Family DP/aivan.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_13',
        nameKey: 'words_quote_13_name',
        relationKey: 'words_relation_apo_babae',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_13',
        photoPath: 'assets/images/Family DP/honey.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_14',
        nameKey: 'words_quote_14_name',
        relationKey: 'words_relation_apo_lalaki',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_14',
        photoPath: 'assets/images/Family DP/Daniel.png',
      ),
    ],
  );

  int _localCount = 124;
  bool _lit = false;
  bool _loading = false;

  int get localCount => _localCount;
  bool get lit => _lit;
  bool get loading => _loading;

  /// Shared candle-count stream. Falls back to an empty stream when
  /// Firebase is not configured (or unreachable), so the section renders
  /// the local counter instead of throwing during build.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> candleStream =
      _buildCandleStream();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _buildCandleStream() {
    try {
      return FirebaseFirestore.instance
          .collection('memorial')
          .doc('anita_lumbao')
          .snapshots();
    } catch (_) {
      return Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
  }

  Future<void> lightCandle() async {
    if (_lit) return;
    _loading = true;
    _lit = true;
    _localCount++;
    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('memorial')
          .doc('anita_lumbao');
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
      _loading = false;
      notifyListeners();
    }
  }
}
