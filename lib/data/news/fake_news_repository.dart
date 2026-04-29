import 'package:dio/dio.dart';

import '../../domain/auth/auth_failure.dart';
import '../../domain/news/news_item.dart';
import '../../domain/news/news_repository.dart';

class APINewsRepository implements NewsRepository {
  APINewsRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  String _desc(Map<String, dynamic> body, String where) =>
      (body['description'] ?? 'Ошибка').toString() + where;

  Future<Map<String, dynamic>> _post(
      String method,
      Map<String, dynamic> data,
      ) async {
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
    if (!_isSuccess(body)) {
      throw Exception(_desc(body, method));
    }
    if (body is! Map<String, dynamic>) {
      throw const ValidationFailure('Некорректный ответ сервера');
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final s = (body['status'] ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }

  Map<String, dynamic> _stringKeyedMap(Map raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) => out[k.toString()] = v);
    return out;
  }

  @override
  Future<List<NewsPost>> fetchPosts({required final int page, required final int limit}) async {
    final post = <String, int>{
      "limit": limit,
      "page": page
    };
    final data = await _post('appGroupsGetLastPosts', post);
    final newsList = data['data'];
    final parsed = (newsList is List)
        ? newsList.whereType<Map>().map((e) {
      final map = _stringKeyedMap(e);
      return NewsPost.fromAPI(map);
    }).toList()
        : <NewsPost>[];
    return parsed;
  }
}
