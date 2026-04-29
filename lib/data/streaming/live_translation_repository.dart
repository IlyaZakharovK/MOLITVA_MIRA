import 'package:dio/dio.dart';
import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

import '../../domain/profile/profile_role.dart';

class LiveTranslation {
  final int id;
  final int type;
  final int statusId;
  final int ownerId;

  final String name;
  final String description;

  final int roomId;
  final String listenerPin;
  final String speakerPin;

  final String coturnUser;
  final String coturnPass;

  final int prayer_optional;
  final String prayer_optional_text;
  final int prayers_category_id;
  final int prayers_texts_id;
  final String invite;

  LiveTranslation({
    required this.id,
    required this.type,
    required this.statusId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.roomId,
    required this.listenerPin,
    required this.speakerPin,
    required this.coturnUser,
    required this.coturnPass,
    required this.prayer_optional,
    required this.prayer_optional_text,
    required this.prayers_category_id,
    required this.prayers_texts_id,
    required this.invite,
  });

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  static String _toStr(dynamic v) => (v ?? '').toString();

  factory LiveTranslation.fromApi(Map<String, dynamic> j) {
    return LiveTranslation(
      id: _toInt(j['id']),
      type: _toInt(j['type']),
      statusId: _toInt(j['status_id']),
      ownerId: _toInt(j['owner_id']),
      name: _toStr(j['name']),
      description: _toStr(j['description']),
      roomId: _toInt(j['roomID']),
      listenerPin: _toStr(j['listener_pin']),
      speakerPin: _toStr(j['speaker_pin']),
      coturnUser: _toStr(j['coturn_user']),
      coturnPass: _toStr(j['coturn_pass']),
      prayer_optional: _toInt(j['prayer_optional']),
      prayer_optional_text: _toStr(j['prayer_optional_text']),
      prayers_category_id: _toInt(j['prayers_category_id']),
      prayers_texts_id: _toInt(j['prayers_texts_id']),
      invite: _toStr(j['invite']),
    );
  }
}

enum TranslationUserModerationAction {
  none,
  ban,
  allowSpeak,
  forbidSpeak,
}

extension TranslationUserModerationActionX on TranslationUserModerationAction {
  String get title {
    switch (this) {
      case TranslationUserModerationAction.none:
        return 'Ничего не делать';
      case TranslationUserModerationAction.ban:
        return 'Забанить на трансляции';
      case TranslationUserModerationAction.allowSpeak:
        return 'Разрешить вещание';
      case TranslationUserModerationAction.forbidSpeak:
        return 'Запретить вещание';
    }
  }
}

class PresenceBanException implements Exception {
  final String message;
  final bool ban;

  const PresenceBanException(this.message, {this.ban = true});

  @override
  String toString() => message;
}

class OnlineUser {
  final int id;
  final String name;
  final ProfileRole role;
  final bool ban;
  final bool speak;

  const OnlineUser({
    required this.id,
    required this.name,
    required this.role,
    required this.ban,
    required this.speak,
  });

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  static String _toStr(dynamic v) => (v ?? '').toString();

  static ProfileRole _parseRole(dynamic raw) {
    final index = _toInt(raw) - 1;
    if (index >= 0 && index < ProfileRole.values.length) {
      return ProfileRole.values[index];
    }
    return ProfileRole.layman;
  }

  OnlineUser copyWith({
    int? id,
    String? name,
    ProfileRole? role,
    bool? ban,
    bool? speak,
  }) {
    return OnlineUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      ban: ban ?? this.ban,
      speak: speak ?? this.speak,
    );
  }

  factory OnlineUser.fromApi(Map<String, dynamic> j) {
    return OnlineUser(
      id: _toInt(j['id']),
      name: _toStr(j['name']),
      role: _parseRole(j['type_id']),
      ban: toBool(j['ban']),
      speak: toBool(j['speak']),
    );
  }
}

class OnlineInfo {
  final int countOnline;
  final List<OnlineUser> users;

  const OnlineInfo({
    required this.countOnline,
    required this.users,
  });

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  factory OnlineInfo.fromApi(Map<String, dynamic> body) {
    final count = _toInt(body['count_online']);

    final usersRaw = body['users'];
    final List<OnlineUser> users = [];
    if (usersRaw is List) {
      for (final u in usersRaw) {
        if (u is Map) {
          users.add(OnlineUser.fromApi(Map<String, dynamic>.from(u)));
        }
      }
    }

    return OnlineInfo(
      countOnline: count,
      users: users,
    );
  }
}

class LiveTranslationRepository {
  LiveTranslationRepository(this._dio);

  final Dio _dio;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  bool _isOkStatus(dynamic status) {
    final s = (status ?? '').toString().toLowerCase().trim();
    return s == 'success' || s == 'ok';
  }

  String _desc(Map<String, dynamic> body) =>
      (body['description'] ?? body['msg'] ?? 'Ошибка').toString();

  Future<LiveTranslation> fetchById(int translationId) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'appGetTranslations',
        'data': <String, dynamic>{'translation_id': translationId},
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final map = Map<String, dynamic>.from(body);
    if (!_isOkStatus(map['status'])) {
      throw Exception(_desc(map));
    }

    final data = map['data'][0];
    if (data is! Map) throw Exception('В ответе нет data by id');

    return LiveTranslation.fromApi(Map<String, dynamic>.from(data));
  }

  Future<LiveTranslation> fetchByInvite(String invite) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'appGetTranslationByInvite',
        'data': <String, dynamic>{'invite': invite},
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final map = Map<String, dynamic>.from(body);
    if (!_isOkStatus(map['status'])) {
      throw Exception(_desc(map));
    }

    final data = map['data'];
    if (data is! Map) throw Exception('В ответе нет data');

    return LiveTranslation.fromApi(Map<String, dynamic>.from(data));
  }

  Future<void> stopTranslation({
    required int translationId,
    required int userId,
  }) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'appStopTranslation',
        'data': <String, dynamic>{
          'translation_id': translationId,
          'user_id': userId,
        },
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final map = Map<String, dynamic>.from(body);
    if (!_isOkStatus(map['status'])) {
      throw Exception(_desc(map));
    }
  }

  Future<OnlineInfo> appUserOnlineInTranslation({
    required int translationId,
    required int userId,
  }) async {
    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': 'appUserOnlineInTranslation',
        'data': <String, dynamic>{
          'translation_id': translationId,
          'user_id': userId,
        },
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final root = Map<String, dynamic>.from(body);
    if (!_isOkStatus(root['status'])) {
      final rootBan = toBool(root['ban']);
      final dataBan = root['data'] is Map
          ? toBool((root['data'] as Map)['ban'])
          : false;

      if (rootBan || dataBan) {
        throw PresenceBanException(_desc(root));
      }

      throw Exception(_desc(root));
    }

    final data = root['data'];
    if (data is Map) {
      final merged = <String, dynamic>{
        ...root,
        ...Map<String, dynamic>.from(data),
      };
      return OnlineInfo.fromApi(merged);
    }

    return OnlineInfo.fromApi(root);
  }

  Future<void> moderateUserInTranslation({
    required int translationId,
    required int actorUserId,
    required int targetUserId,
    required TranslationUserModerationAction action,
  }) async {
    if (action == TranslationUserModerationAction.none) return;

    final int actionType;
    switch (action) {
      case TranslationUserModerationAction.ban:
        actionType = 1;
        break;
      case TranslationUserModerationAction.allowSpeak:
        actionType = 2;
        break;
      case TranslationUserModerationAction.forbidSpeak:
        actionType = 3;
        break;
      case TranslationUserModerationAction.none:
        return;
    }

    final resp = await _dio.post(
      '',
      data: <String, dynamic>{
        'type': _type,
        'pass': _pass,
        'method': "appChatModerateUsers",
        'data': <String, dynamic>{
          'translation_id': translationId,
          'my_user_id': actorUserId,
          'user_id': targetUserId,
          "type_action": actionType
        },
      },
    );

    final body = resp.data;
    if (body is! Map) throw Exception('Некорректный ответ сервера');

    final map = Map<String, dynamic>.from(body);
    if (!_isOkStatus(map['status'])) {
      throw Exception(_desc(map));
    }
  }
}