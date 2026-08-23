class TributeModel {
  final String tributeMessageKey;
  final List<FamilyQuote> familyQuotes;

  const TributeModel({
    required this.tributeMessageKey,
    required this.familyQuotes,
  });
}

class FamilyQuote {
  final String quoteKey;
  final String nameKey;

  const FamilyQuote({required this.quoteKey, required this.nameKey});
}
