/// One row from `visitors` for the family admin page.
class AdminVisitor {
  final String id;
  final String name;
  final String address;
  final String lang;
  final DateTime createdAt;

  const AdminVisitor({
    required this.id,
    required this.name,
    required this.address,
    required this.lang,
    required this.createdAt,
  });
}
