class TributeModel {
  final String tributeMessage;
  final List<FamilyQuote> familyQuotes;

  const TributeModel({
    required this.tributeMessage,
    required this.familyQuotes,
  });
}

class FamilyQuote {
  final String quote;
  final String name;
  const FamilyQuote({required this.quote, required this.name});
}
