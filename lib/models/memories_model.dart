class MemoriesModel {
  final List<MemoryItem> memories;
  const MemoriesModel({required this.memories});
}

class MemoryItem {
  final String icon;
  final String titleKey;
  final String bodyKey;

  const MemoryItem({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
}
