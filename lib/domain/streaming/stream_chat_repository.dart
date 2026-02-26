import 'package:dio/dio.dart';

import '../../data/auth/auth_local_store.dart';
import '../../domain/streaming/chat_message.dart';

abstract class StreamChatRepository {
  Future<List<ChatMessage>> fetchMessages({
    required int translationId,
    required int userId,
  });

  Future<List<ChatMessage>> fetchNewMessages({
    required int translationId,
    required int userId,
    required int lastMessageId,
  });

  Future<void> sendMessage({
    required int translationId,
    required int userId,
    required String text,
  });
}

class ApiStreamChatRepository implements StreamChatRepository {
  ApiStreamChatRepository({
    required Dio dio,
    required AuthLocalStore local,
  })  : _dio = dio,
        _local = local;

  final Dio _dio;
  final AuthLocalStore _local;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

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
    if (body is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    return Map<String, dynamic>.from(body as Map);
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final s = (body['status'] ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }

  String _desc(Map<String, dynamic> body) =>
      (body['description'] ?? 'Ошибка').toString();

  @override
  Future<List<ChatMessage>> fetchMessages({
    required int translationId,
    required int userId,
  }) async {
    final body = await _post('appGetChatMessagesTranslation', {
      'translation_id': translationId,
      'user_id': userId,
    });

    if (!_isSuccess(body)) throw Exception(_desc(body));

    final data = body['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) {
      final author = (e['author'] ?? '').toString().trim().toLowerCase();
      final avatar = (e['avatar_url'] ?? '').toString().trim();
      final isMine = author == 'текущий пользователь' || avatar.isEmpty;
      return ChatMessage.fromApiJson(e, isMine: isMine);
    })
        .toList(growable: false);
  }

  @override
  Future<List<ChatMessage>> fetchNewMessages({
    required int translationId,
    required int userId,
    required int lastMessageId,
  }) async {
    final body = await _post('appStartChatAutoUpdate', {
      'translation_id': translationId,
      'user_id': userId,
      'lastMessageId': lastMessageId,
    });

    if (!_isSuccess(body)) throw Exception(_desc(body));

    final data = body['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) {
      final author = (e['author'] ?? '').toString().trim().toLowerCase();
      final avatar = (e['avatar_url'] ?? '').toString().trim();
      final isMine = author == 'текущий пользователь' || avatar.isEmpty;
      return ChatMessage.fromApiJson(e, isMine: isMine);
    })
        .toList(growable: false);
  }

  @override
  Future<void> sendMessage({
    required int translationId,
    required int userId,
    required String text,
  }) async {
    var uid = userId;
    if (uid <= 0) {
      final raw = await _local.getToken();
      uid = int.tryParse((raw ?? '').toString()) ?? 0;
    }
    if (uid <= 0) throw Exception('Нет user_id: не авторизован');

    const method = 'appSendMessageToChat';

    final body = await _post(method, {
      'translation_id': translationId,
      'user_id': userId,
      'message': text,
    });

    if (!_isSuccess(body)) throw Exception(_desc(body));
  }
}
