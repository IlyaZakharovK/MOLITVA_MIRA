import 'package:vsem_mirom/domain/streams/stream_status_id.dart';
import 'package:vsem_mirom/domain/streams/stream_type.dart';

import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

class StreamItem {
  final String id;

  final String title;

  final String description;

  final int participants;

  final DateTime startAt;

  final DateTime endAt;

  final StreamStatusID statusId;

  final String image;

  final StreamType typeId;

  final int likes;
  final bool isLiked;

  final String prayText;

  final String invite;
  final bool saveMediaTranslation;
  final String saveMediaTranslationUrl;

  const StreamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.startAt,
    required this.endAt,
    required this.invite,
    required this.statusId,
    required this.typeId,
    required this.image,
    required this.likes,
    required this.isLiked,
    required this.prayText,
    required this.saveMediaTranslation,
    required this.saveMediaTranslationUrl,
  });

  factory StreamItem.fromApiJson(Map<String, dynamic> json) {
    final typeId = toInt(json['type']);
    final type = StreamTypeIDApiX.fromApi(typeId);

    final statusId = toInt(json['status_id']);
    final status = StreamStatusIDApiX.fromApi(statusId);
    final saveMediaTranslation = toBool(json['saveMediaTranslation']);
    final saveMediaTranslationUrl = saveMediaTranslation
        ? toStr(json['saveMediaTranslationUrl'])
        : '0';

    return StreamItem(
      id: toStr(json['id']),
      title: toStr(json['name']),
      description: toStr(json['description']),
      participants: toInt(json['participants']),
      startAt: parseDt(json['date_planned']),
      endAt: parseDt(json['date_end']),
      typeId: type,
      statusId: status,
      image: toStr(json['logo_url']),
      likes: toInt(json['likes_count']),
      isLiked: toBool(json['is_subscribed']),
      prayText: toStr(json['prayer_text']),
      invite: toStr(json['invite']).trim(),
      saveMediaTranslation: saveMediaTranslation,
      saveMediaTranslationUrl: saveMediaTranslationUrl,
    );
  }
}
