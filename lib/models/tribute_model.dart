/// Group a family quote belongs to — mirrors the Words page filter chips
/// (Lahat / Mga anak / Mga kapatid / Mga apo).
enum QuoteGroup { children, siblings, grandchildren }

class TributeModel {
  final String tributeMessageKey;

  /// The family's words for Nanay, shown on the Words tab.
  final List<FamilyQuote> familyQuotes;

  /// The pinned/featured quote rendered in the special highlighted card
  /// above the regular quote list. Its [FamilyQuote.group] also drives the
  /// default "Lahat" featured card content.
  final FamilyQuote featuredQuote;

  const TributeModel({
    required this.tributeMessageKey,
    required this.familyQuotes,
    required this.featuredQuote,
  });
}

class FamilyQuote {
  final String quoteKey;
  final String nameKey;

  /// Localized relation label key, e.g. 'words_relation_bunso' —
  /// rendered under the name ("— Lorie Salvador · Bunso").
  final String relationKey;

  /// Optional portrait asset, e.g. 'assets/images/Family DP/lorie.jpg'.
  /// Null falls back to a gradient initials avatar.
  final String? photoPath;

  /// Which filter chip this quote belongs to.
  final QuoteGroup group;

  /// Localized "Naiwan noong ..." date key, e.g. 'words_date_1'.
  final String dateKey;

  const FamilyQuote({
    required this.quoteKey,
    required this.nameKey,
    required this.relationKey,
    required this.group,
    required this.dateKey,
    this.photoPath,
  });
}
