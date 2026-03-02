import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio, );

  /// type: 1 user avatar, 2 community avatar, 3 translation avatar
  /// imgId: id user/community/translation
  ///
  /// Возвращаем сырое тело ответа, чтобы ты мог посмотреть, что реально прилетает.
  Future<Map<String, dynamic>> uploadImageBase64({
    required int type,
    required int imgId,
    required Uint8List bytes,
  }) async {
    final b64 = base64Encode(bytes);
    print(b64);

    final payload = {
      "type": "application",
      "pass": 'f92R*#eiDF82W@#k2WO',
      "method": "appUploadImg",
      "data": {
        "type": type,
        "img": b64,
        "img_id": imgId,
      }
    };

    final res = await _dio.post('', data: payload);

    final data = res.data;
    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }

    throw Exception('Unexpected response type: ${data.runtimeType}');
  }
}