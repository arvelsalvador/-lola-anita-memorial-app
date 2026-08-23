class FavoritesModel {
  final List<FavoriteSection> sections;
  const FavoritesModel({required this.sections});
}

class FavoriteSection {
  /// Icon key resolved to an IconData in the view:
  /// 'spa' | 'music' | 'tv' | 'heart'.
  final String iconKey;

  /// Localized section title, e.g. 'section_hobbies'.
  final String titleKey;

  /// Localized item keys shown as bulleted lines, e.g. 'fav_hobby_1'.
  final List<String> itemKeys;

  const FavoriteSection({
    required this.iconKey,
    required this.titleKey,
    required this.itemKeys,
  });
}
