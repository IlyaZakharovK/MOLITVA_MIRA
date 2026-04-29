import "package:dio/dio.dart";
import "package:vsem_mirom/domain/prays/prays_repository.dart";

import "../../domain/funcs/parseFuncs.dart";
import "../../domain/prays/pray_category_item.dart";
import "../../domain/prays/pray_list_item.dart";

class ApiPraysRepository implements PrayRepository {
  ApiPraysRepository({required Dio dio})
      : _dio = dio;

  final Dio _dio;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  bool _isSuccess(Map<String, dynamic> body) {
    final s = (body['status'] ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }

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
      options: Options(
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );

    final body = resp.data;

    if (body is Map) {
      return stringKeyedMap(body);
    }

    throw Exception('Некорректный ответ сервера');
  }

  @override
  Future<ListPrayCategories> fetchPrayCategories() async {
    final post = <String, dynamic>{
    };
    final data = await _post("appGetPrayersCategory", post);
    if(!_isSuccess(data)){
      throw Exception('Пупупу');
    }
    return ListPrayCategories.fromAPI(data['data']);
  }

  @override
  Future<ListPrayItem> fetchPraysInCategory({
    required int categoryId
  }) async {
    final post = <String, dynamic>{
      "category_id": categoryId
    };
    final data = await _post("appGetPrayersByCategory", post);
    if(!_isSuccess(data)){
      throw Exception('Пупупу');
    }
    return ListPrayItem.fromAPI(data['data']);
  }
}
