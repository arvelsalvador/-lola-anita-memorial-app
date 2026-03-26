import 'package:flutter/material.dart';
import 'package:nita/Pages/Tributes/Model/tribute_model.dart';

class TributeController extends ChangeNotifier {
  static const TributeModel data = TributeModel(
    tributeMessage:
        'You taught us that a home is built with warmth, not walls. '
        'Your laugh lives in every room we\'ve ever loved. '
        'Rest now, Lola. We carry you forward.',
    familyQuotes: [
      FamilyQuote(
        quote: 'Mama was light itself. Every room she entered felt warmer.',
        name: 'Maria, her eldest daughter',
      ),
      FamilyQuote(
        quote:
            'She never let us leave hungry or unloved. That was her superpower.',
        name: 'Carlo, grandson',
      ),
      FamilyQuote(
        quote:
            'I will spend my whole life trying to love people the way she loved us.',
        name: 'Ana, granddaughter',
      ),
    ],
  );
}
