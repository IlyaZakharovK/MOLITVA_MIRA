import 'stream_status.dart';

class StreamItem {
  final String id;

  /// Название трансляции
  final String title;

  /// Короткое описание
  final String description;

  /// Кол-во участников (в API нет — ставим 0)
  final int participants;

  /// Время начала (берем date_planned)
  final DateTime startAt;

  /// Статус
  final StreamStatus status;

  const StreamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.startAt,
    required this.status,
  });

  factory StreamItem.fromApiJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? '').toString(); // active/future/completed
    final st = StreamStatusApiX.fromApi(statusStr);

    DateTime parseDt(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      // формат "YYYY-MM-DD HH:mm:ss"
      final iso = s.replaceFirst(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.now();
    }

    return StreamItem(
      id: (json['id'] ?? '').toString(),
      title: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      participants: 0,
      startAt: parseDt((json['date_planned'] ?? '').toString()),
      status: st,
    );
  }
}
