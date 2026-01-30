import 'package:dio/dio.dart';

import '../../data/auth/auth_local_store.dart';
import '../../domain/streams/streams_item.dart';
import '../../domain/streams/stream_status.dart';
import '../../domain/streams/streams_repository.dart';

class LikeTranslationResult {
  final String description;
  final int count;

  const LikeTranslationResult({required this.description, required this.count});
}

class OnlineUser {
  final int id;
  final String name;

  const OnlineUser({required this.id, required this.name});
}

class OnlineUsersResult {
  final int count;
  final List<OnlineUser> users;

  const OnlineUsersResult({required this.count, required this.users});
}

class ApiStreamsRepository implements StreamsRepository {
  ApiStreamsRepository({
    required Dio dio,
    required AuthLocalStore local,
  })  : _dio = dio,
        _local = local;

  final Dio _dio;
  final AuthLocalStore _local;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  Future<Map<String, dynamic>> _post(String method, Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': method,
        'data': data,
      },
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );

    final body = resp.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера');
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final s = (body['status'] ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }
  String _desc(Map<String, dynamic> body) => (body['description'] ?? 'Ошибка').toString();
  int _toInt(dynamic v, {int def = 0}) => int.tryParse((v ?? def).toString()) ?? def;

  @override
  Future<StreamsPage> fetchStreams({
    required StreamStatus status,
    required int from,
    required int limit,
    required bool my,
  }) async {
    final data = <String, dynamic>{
      'type': status.apiType,
      'from': from,
      'limit': limit,
    };

    if (my) {
      final raw = await _local.getToken();
      if (raw == null) throw Exception('Нет user_id: не авторизован');
      final userId = int.tryParse(raw.toString());
      if (userId == null) throw Exception('Некорректный user_id');
      data['user_id'] = userId;
    }

    final body = await _post('appGetTranslations', data);

    if (!_isSuccess(body)) {
      throw Exception(_desc(body));
    }

    final list = body['data'];
    final meta = body['meta'];

    final items = (list is List)
        ? list
        .whereType<Map>()
        .map((e) => StreamItem.fromApiJson(Map<String, dynamic>.from(e)))
        .toList()
        : <StreamItem>[];

    int total = items.length;
    int mFrom = from;
    int mLimit = limit;

    if (meta is Map) {
      total = _toInt(meta['total'], def: total);
      mFrom = _toInt(meta['from'], def: from);
      mLimit = _toInt(meta['limit'], def: limit);
    }

    return StreamsPage(items: items, total: total, from: mFrom, limit: mLimit);
  }

  /// appLikeTranslation
  Future<LikeTranslationResult> likeTranslation({
    required int translationId,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) {
      throw Exception('Нет user_id: не авторизован');
    }
    final userId = int.tryParse(raw.toString());
    if (userId == null) {
      throw Exception('Некорректный user_id');
    }

    final body = await _post('appLikeTranslation', {
      'translation_id': translationId,
      'user_id': userId,
    });

    if (!_isSuccess(body)) throw Exception(_desc(body));

    final count = _toInt(body['count'], def: 0);
    return LikeTranslationResult(description: _desc(body), count: count);
  }
}
