import 'package:vsem_mirom/domain/streams/stream_status_id.dart';
import 'package:vsem_mirom/domain/streams/stream_type.dart';

import 'stream_status.dart';

class StreamItem {
  final String id;

  /// Название трансляции
  final String title;

  /// Короткое описание
  final String description;

  /// Кол-во участников
  final int participants;

  /// Время начала (date_planned)
  final DateTime startAt;

  final DateTime endAt;

  /// Статус id (1..4)
  final StreamStatusID status_id;

  final String image;

  /// Тип (1..4)
  final StreamType type_id;

  final int likes;

  /// invite-код (есть только для некоторых типов)
  final String invite;

  const StreamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.startAt,
    required this.endAt,
    required this.invite,
    required this.status_id,
    required this.type_id,
    required this.image,
    required this.likes,
  });

  factory StreamItem.fromApiJson(Map<String, dynamic> json) {
    String toStr(dynamic v) => (v ?? '').toString();

    int toInt(dynamic v, [int def = 0]) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? def;
    }

    DateTime parseDt(dynamic v) {
      final s = toStr(v).trim();
      if (s.isEmpty) return DateTime.now();
      final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.now();
    }

    final statusStr = toStr(json['status']);
    final st = StreamStatusApiX.fromApi(statusStr);

    final typeId = toInt(json['type']);
    final type = StreamTypeIDApiX.fromApi(typeId);

    final statusId = toInt(json['status_id']);
    final status = StreamStatusIDApiX.fromApi(statusId);

    return StreamItem(
      id: toStr(json['id']),
      title: toStr(json['name']),
      description: toStr(json['description']),
      participants: toInt(json['participants']),
      startAt: parseDt(json['date_planned']),
      endAt: parseDt(json['date_end']),
      type_id: type,
      status_id: status,
      image: toStr(json['img']),
      likes: toInt(json['likes']),
      invite: toStr(json['invite']).trim(),
    );
  }
}
