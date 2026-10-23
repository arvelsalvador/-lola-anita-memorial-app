import 'package:flutter/material.dart';
import 'package:nita/models/words_model.dart';

/// Quotes for the Words tab only (matches words_page.dart).
/// Candle state lives in CondolencesController so each page owns its logic.
class WordsController extends ChangeNotifier {
  static const WordsModel data = WordsModel(
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
        photoPath: 'assets/images/family_dp/lorie.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_2',
        nameKey: 'words_quote_2_name',
        relationKey: 'words_relation_panganay',
        group: QuoteGroup.children,
        dateKey: 'words_date_2',
        photoPath: 'assets/images/family_dp/gernan.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_3',
        nameKey: 'words_quote_3_name',
        relationKey: 'words_relation_ikalawa',
        group: QuoteGroup.children,
        dateKey: 'words_date_3',
        photoPath: 'assets/images/family_dp/Odin.jpg',
      ),
      // ── Mga kapatid (siblings) ────────────────────────────────────────
      FamilyQuote(
        quoteKey: 'words_quote_4',
        nameKey: 'words_quote_4_name',
        relationKey: 'words_relation_kapatid_lalaki',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_4',
        photoPath: 'assets/images/family_dp/obit.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_5',
        nameKey: 'words_quote_5_name',
        relationKey: 'words_relation_kapatid_lalaki',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_5',
        photoPath: 'assets/images/family_dp/dolfo.jpg',
      ),
      FamilyQuote(
        quoteKey: 'words_quote_6',
        nameKey: 'words_quote_6_name',
        relationKey: 'words_relation_kapatid_babae',
        group: QuoteGroup.siblings,
        dateKey: 'words_date_6',
        photoPath: 'assets/images/family_dp/sonia.jpg',
      ),
      // ── Mga apo (grandchildren) ───────────────────────────────────────
      FamilyQuote(
        quoteKey: 'words_quote_11',
        nameKey: 'words_quote_11_name',
        relationKey: 'words_relation_apo_lalaki',
        group: QuoteGroup.grandchildren,
        dateKey: 'words_date_11',
        photoPath: 'assets/images/family_dp/arvel.jpg',
      ),
    ],
  );
}
