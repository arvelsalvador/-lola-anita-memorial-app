import 'package:flutter/material.dart';
import 'package:nita/models/tribute_model.dart';

class TributeController extends ChangeNotifier {
  static const TributeModel data = TributeModel(
    tributeMessageKey: 'tribute_message',
    familyQuotes: [
      FamilyQuote(
        quoteKey: 'family_quote_1',
        nameKey: 'family_quote_1_name',
      ),
      FamilyQuote(
        quoteKey: 'family_quote_2',
        nameKey: 'family_quote_2_name',
      ),
      FamilyQuote(
        quoteKey: 'family_quote_3',
        nameKey: 'family_quote_3_name',
      ),
    ],
  );
}
