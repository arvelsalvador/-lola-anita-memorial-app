class HomeModel {
  final String name;
  final String initial;
  final int birthYear;
  final int passingYear;
  final String tagline;

  const HomeModel({
    required this.name,
    required this.initial,
    required this.birthYear,
    required this.passingYear,
    required this.tagline,
  });

  String get years => '$birthYear  ·  $passingYear';
}
