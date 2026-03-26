class MemoriesModel {
  final List<MemoryItem> memories;
  const MemoriesModel({required this.memories});
}

class MemoryItem {
  final String icon;
  final String title;
  final String body;
  const MemoryItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}
