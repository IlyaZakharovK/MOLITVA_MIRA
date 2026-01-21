import 'package:dio/dio.dart';
import '../../domain/dioceses/diocese.dart';
import '../../domain/dioceses/dioceses_repository.dart';

class ApiDiocesesRepository implements DiocesesRepository {
  ApiDiocesesRepository(this._dio);

  final Dio _dio;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  @override
  Future<List<Diocese>> getDioceses() async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'getDioceses',
        'data': <String, dynamic>{},
      },
    );

    final body = resp.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера');
    }

    final status = (body['status'] ?? '').toString();
    if (status != 'success') {
      throw Exception((body['description'] ?? 'Ошибка').toString());
    }

    final list = body['dioceses'];
    if (list is! List) return const <Diocese>[];

    return list
        .whereType<Map>()
        .map((e) => Diocese.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
