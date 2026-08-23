import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nita/models/tribute_model.dart';

class TributeController extends ChangeNotifier {
  static const TributeModel data = TributeModel(
    tributeMessageKey: 'tribute_message',
    familyQuotes: [
      FamilyQuote(quoteKey: 'family_quote_1', nameKey: 'family_quote_1_name'),
      FamilyQuote(quoteKey: 'family_quote_2', nameKey: 'family_quote_2_name'),
      FamilyQuote(quoteKey: 'family_quote_3', nameKey: 'family_quote_3_name'),
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
