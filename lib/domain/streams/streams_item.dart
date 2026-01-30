import 'package:vsem_mirom/domain/streams/stream_status_id.dart';
import 'package:vsem_mirom/domain/streams/stream_type.dart';

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

  final DateTime endAt;

  /// Статус
  final StreamStatus status;

  /// Статус id
  final StreamStatusID status_id;

  final String image;

  /// Тип
  final StreamType type_id;
  final int likes;

  const StreamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.status_id,
    required this.type_id,
    required this.image,
    required this.likes,
  });

  factory StreamItem.fromApiJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? '').toString();
    final st = StreamStatusApiX.fromApi(statusStr);
    final typeId = (json['type'] as num?)?.toInt() ?? 0;
    final type = StreamTypeIDApiX.fromApi(typeId);
    final statusId = (json['status_id'] as num?)?.toInt() ?? 0;
    final status = StreamStatusIDApiX.fromApi(statusId);

    DateTime parseDt(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      final iso = s.replaceFirst(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.now();
    }

    return StreamItem(
      id: (json['id'] ?? '').toString(),
      title: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      participants:(json['participants'] ?? 0),
      startAt: parseDt((json['date_planned'] ?? '').toString()),
      endAt: parseDt((json['date_end'] ?? '').toString()),
      status: st,
      type_id: type,
      status_id: status,
      image: (json['img'] ?? '').toString(),
      likes:(json['likes'] ?? 0),
    );
  }
}
