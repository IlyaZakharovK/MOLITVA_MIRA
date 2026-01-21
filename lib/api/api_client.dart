import 'package:dio/dio.dart';
import '../data/auth/auth_local_store.dart';
import 'api_config.dart';

class ApiResponse {
  ApiResponse({required this.status, required this.description});

  final String status;
  final String description;

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: (json['status'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

class ApiClient {
  ApiClient(this._dio, this._local);

  final Dio _dio;
  final AuthLocalStore _local;

  Future<ApiResponse> call({
    required String method,
    required Map<String, dynamic> data,
    bool auth = false,
  }) async {
    final token = await _local.getToken();

    if (auth && (token == null)) {
      throw ApiException('Не авторизован: нет user_id');
    }
    final userId = auth ? (token) : null;

    final payload = <String, dynamic>{
      'type': ApiConfig.type,
      'pass': ApiConfig.pass,
      'method': method,
      'data': data,
      if (auth) 'user_id': userId,
    };

    final resp = await _dio.post('', data: payload);

    final body = resp.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('Некорректный ответ сервера');
    }

    return ApiResponse.fromJson(body);
  }
}
