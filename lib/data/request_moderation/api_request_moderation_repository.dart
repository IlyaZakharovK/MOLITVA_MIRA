import 'package:dio/dio.dart';

import '../../domain/request_moderation/request_moderation_item.dart';
import '../../domain/request_moderation/request_moderation_repository.dart';

class ApiRequestModerationRepository implements RequestModerationRepository {
  final Dio dio;
  final String apiPass;

  ApiRequestModerationRepository({
    required this.dio,
    required this.apiPass,
  });

  Future<Map<String, dynamic>> _post(String method, Map<String, dynamic> data) async {
    final payload = {
      "type": "application",
      "pass": apiPass,
      "method": method,
      "data": data,
    };

    final resp = await dio.post(
      '',
      data: payload,
    );

    final body = resp.data;
    if (body is! Map) {
      throw Exception('Некорректный ответ сервера');
    }

    final map = Map<String, dynamic>.from(body as Map);

    if (map['status'] != 'success' && map['status'] != 'ok') {
      throw Exception(map['description']?.toString() ?? 'Ошибка сервера');
    }

    return map;
  }

  @override
  Future<List<RequestModerationItem>> fetch({
    required int statusId,
    required int page,
    required int limit,
  }) async {
    final map = await _post('appRequestModeration', {
      "status_id": statusId,
      "page": page,
      "limit": limit,
    });

    final data = map['data'];
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((e) => RequestModerationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false)..sort((a, b) {
      final aSos = a.typeId == 4;
      final bSos = b.typeId == 4;
      if (aSos != bSos) return aSos ? -1 : 1;
      return b.id.compareTo(a.id);
    });
  }

  @override
  Future<String> bless(int requestId) async {
    final map = await _post('appTranslationModeration', {
      "translation_id": requestId,
      "status_id": 2,
    });
    return map['description'];
  }

  @override
  Future<String> reject(int requestId) async {
    final map = await _post('appTranslationModeration', {
      "translation_id": requestId,
      "status_id": 3,
    });
    print(map);
    return map['description'];
  }
}
