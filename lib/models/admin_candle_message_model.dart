/// One row from `candle_messages` for the family admin page.
class AdminCandleMessage {
  final String id;
  final String name;
  final String message;
  final DateTime createdAt;

  const AdminCandleMessage({
    required this.id,
    required this.name,
    required this.message,
    required this.createdAt,
  });
}
