class PrayerCategory {
  final int id;
  final String name;

  const PrayerCategory({required this.id, required this.name});

  factory PrayerCategory.fromJson(Map<String, dynamic> json) {
    return PrayerCategory(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
