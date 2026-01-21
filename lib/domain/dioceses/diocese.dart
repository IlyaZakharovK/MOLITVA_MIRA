class Diocese {
  final int id;
  final String name;

  const Diocese({required this.id, required this.name});

  factory Diocese.fromJson(Map<String, dynamic> json) {
    return Diocese(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
