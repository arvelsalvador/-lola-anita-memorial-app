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
