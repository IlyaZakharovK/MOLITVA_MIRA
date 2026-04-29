import 'package:dio/dio.dart';
import 'package:vsem_mirom/domain/help/help_repository.dart';

import 'package:vsem_mirom/domain/auth/auth_failure.dart';
import 'package:vsem_mirom/domain/help/help_chat_message_item.dart';
import 'package:vsem_mirom/data/auth/auth_local_store.dart';

class ApiHelpRepository implements HelpRepository {
  ApiHelpRepository({required Dio dio, required AuthLocalStore localStore})
    : _dio = dio,
      _local = localStore;

  final Dio _dio;
  final AuthLocalStore _local;

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
    final d = (body['description'] ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok' || d == 'чат не найден.';
  }

  Map<String, dynamic> _stringKeyedMap(Map raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) => out[k.toString()] = v);
    return out;
  }

  @override
  Future<List<HelpChatMessageItem>> fetchHelpChat() async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{'user_id': userId};
    final data = await _post('appGetChatMessagesSupport', post);
    final listMessages = data['data'];
    return (listMessages is List)
        ? listMessages.whereType<Map>().map((e) {
            final map = _stringKeyedMap(e);
            return HelpChatMessageItem.fromAPI(map);
          }).toList()
        : <HelpChatMessageItem>[];
  }

  @override
  Future<bool> sendMessage({required String message}) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{
      "sender_id": userId,
      "recipient_id": 0,
      "message": message,
    };
    final data = await _post('appSendMessageToChatSupport', post);
    return _isSuccess(data);
  }

  @override
  Future<List<HelpChatMessageItem>> refreshHelpChat({
    required int lastMessageId,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{
      'user_id': userId,
      'lastMessageId': lastMessageId,
    };
    final data = await _post('appStartChatAutoUpdateSupport', post);
    final listMessages = data['data'];
    return (listMessages is List)
        ? listMessages.whereType<Map>().map((e) {
            final map = _stringKeyedMap(e);
            return HelpChatMessageItem.fromAPI(map);
          }).toList()
        : <HelpChatMessageItem>[];
  }
}
