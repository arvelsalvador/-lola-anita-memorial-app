class HomeModel {
  final String name;
  final String initial;
  final int birthYear;
  final int passingYear;

  const HomeModel({
    required this.name,
    required this.initial,
    required this.birthYear,
    required this.passingYear,
  });
}

class StoryModel {
  final String quoteKey;
  final String quoteAttributionKey;
  final String aboutKey;
  final String favorites;
  final List<LifeEvent> timeline;

  const StoryModel({
    required this.quoteKey,
    required this.quoteAttributionKey,
    required this.aboutKey,
    required this.favorites,
    required this.timeline,
  });
}

class LifeEvent {
  final String year;
  final String titleKey;
  final String descriptionKey;
  final bool isLast;

  const LifeEvent({
    required this.year,
    required this.titleKey,
    required this.descriptionKey,
    this.isLast = false,
  });
}

class MemoriesModel {
  final List<MemoryItem> memories;
  const MemoriesModel({required this.memories});
}

class MemoryItem {
  /// Stable unique identifier, separate from [titleKey] — titleKey is a
  /// localization key and isn't guaranteed unique on its own if entries
  /// are ever copy-pasted. Used for ValueKeys and any future lookups.
  final String id;

  final String icon;
  final String titleKey;
  final String bodyKey;

  /// Category used by the filter tabs on the memories page. One of
  /// 'mem_filter_life' | 'mem_filter_family' | 'mem_filter_celebrations'.
  final String category;

  /// Era label shown above the title, e.g. '1940s'.
  final String decade;

  /// How many gallery photos this memory points to (shown in the card
  /// footer next to "Tingnan sa Galeri").
  final int photoCount;

  const MemoryItem({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.category,
    required this.decade,
    required this.photoCount,
  });
}
