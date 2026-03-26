class StoryModel {
  final String quote;
  final String quoteAttribution;
  final String about;
  final List<LifeEvent> timeline;

  const StoryModel({
    required this.quote,
    required this.quoteAttribution,
    required this.about,
    required this.timeline,
  });
}

class LifeEvent {
  final String year;
  final String title;
  final String description;
  final bool isLast;

  const LifeEvent({
    required this.year,
    required this.title,
    required this.description,
    this.isLast = false,
  });
}
