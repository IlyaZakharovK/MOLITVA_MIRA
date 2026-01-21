class PrayerText {
  final int id;
  final String name;
  final String text;

  const PrayerText({
    required this.id,
    required this.name,
    required this.text,
  });

  factory PrayerText.fromJson(Map<String, dynamic> json) {
    return PrayerText(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}
