import 'package:dio/dio.dart';

import '../../data/auth/auth_local_store.dart';
import '../../domain/prayer_request/prayer_category.dart';
import '../../domain/prayer_request/prayer_request_repository.dart';
import '../../domain/prayer_request/prayer_text.dart';

import '../../api/api_config.dart';

class ApiPrayerRequestRepository implements PrayerRequestRepository {
  final Dio _dio;
  final AuthLocalStore _local;

  ApiPrayerRequestRepository(this._dio, this._local);

  Future<Map<String, dynamic>> _postRaw(String method, Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': ApiConfig.type,
        'pass': ApiConfig.pass,
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

  bool _isSuccess(Map<String, dynamic> body) => (body['status'] ?? '') == 'success' || (body['status'] ?? '') == 'ok';
  String _desc(Map<String, dynamic> body) => (body['description'] ?? 'Ошибка').toString();

  @override
  Future<List<PrayerCategory>> getCategories() async {
    final body = await _postRaw('appGetPrayersCategory', {});
    if (!_isSuccess(body)) {
      throw Exception(_desc(body));
    }

    final list = body['data'];
    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((e) => PrayerCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PrayerText>> getPrayersByCategory(int categoryId) async {
    final body = await _postRaw('appGetPrayersByCategory', {'category_id': categoryId});
    if (!_isSuccess(body)) {
      throw Exception(_desc(body));
    }

    final list = body['data'];
    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((e) => PrayerText.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> createTranslation({
    required String name,
    required String description,
    required int type,
    required DateTime datePlanned,
    int? prayersCategoryId,
    int? prayersTextId,
    required bool prayerOptional,
    required String prayerOptionalText,
  }) async {
    final userId = await _local.getToken(); // у тебя возвращает int?
    if (userId == null) throw Exception('Не найден user_id (не авторизован)');

    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'prayer_optional': prayerOptional ? 1 : 0,
      'prayer_optional_text': prayerOptional ? prayerOptionalText : '',
      'type': type,
      'date_planned': _fmt(datePlanned),
      'user_id': userId,
    };

    // если своя молитва — эти поля должны быть None -> мы их НЕ отправляем вообще
    if (!prayerOptional) {
      payload['prayers_category_id'] = prayersCategoryId;
      payload['prayers_texts_id'] = prayersTextId;
    } else {
      payload['prayers_category_id'] = 0;
      payload['prayers_texts_id'] = 0;
    }

    final body = await _postRaw('appCreateTranslation', payload);

    if (!_isSuccess(body)) {
      throw Exception(_desc(body));
    }
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }
}
