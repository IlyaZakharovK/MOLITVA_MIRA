import 'package:dio/dio.dart';

import '../../data/auth/auth_local_store.dart';
import '../../domain/streams/streams_item.dart';
import '../../domain/streams/stream_status.dart';
import '../../domain/streams/streams_repository.dart';

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
    );

    final body = resp.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера');
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) => (body['status'] ?? '').toString() == 'success';
  String _desc(Map<String, dynamic> body) => (body['description'] ?? 'Ошибка').toString();

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
      final userId = await _local.getToken();
      if (userId == null) throw Exception('Нет user_id: не авторизован');
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
      total = int.tryParse((meta['total'] ?? total).toString()) ?? total;
      mFrom = int.tryParse((meta['from'] ?? from).toString()) ?? from;
      mLimit = int.tryParse((meta['limit'] ?? limit).toString()) ?? limit;
    }

    return StreamsPage(items: items, total: total, from: mFrom, limit: mLimit);
  }
}
