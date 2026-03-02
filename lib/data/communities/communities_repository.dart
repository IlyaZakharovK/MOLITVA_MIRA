import 'package:dio/dio.dart';
import 'package:vsem_mirom/domain/community_details/community_details.dart';

import '../../domain/auth/auth_failure.dart';
import '../../domain/communities/communities_repository.dart';
import '../../domain/communities/community_item.dart';
import '../../domain/funcs/parseFuncs.dart';
import '../auth/auth_local_store.dart';

class APICommunitiesRepository implements CommunitiesRepository {
  APICommunitiesRepository({
    required Dio dio,
    required AuthLocalStore localStore,
  })
      : _dio = dio,
        _local = localStore;

  final Dio _dio;
  final AuthLocalStore _local;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  String _desc(Map<String, dynamic> body) =>
      (body['description'] ?? 'Ошибка').toString();

  Future<Map<String, dynamic>> _post(String method,
      Map<String, dynamic> data,) async {
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
      throw Exception(_desc(body));
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
  Future<List<CommunityItem>> searchCommunities({
    required String request,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизоват');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final data = <String, dynamic>{
      "search": request,
      "user_id": userId
    };
    final body = await _post('appGetGroups', data);
    final list = body['data'];

    final parsed = (list is List)
        ? list.whereType<Map>().map((e) {
      final map = _stringKeyedMap(e);
      return CommunityItem.fromApiJson(map);
    }).toList()
        : <CommunityItem>[];
    return parsed;
  }

  @override
  Future<List<CommunityItem>> fetchCommunities({
    required int page,
    required int limit,
    required bool my
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final String userIdKey = my? 'user_id': 'my_user_id';
    final data =<String, dynamic>{
      'page': page,
      'limit': limit,
      userIdKey: userId,
    };
    final body = await _post('appGetGroups', data);
    final list = body['data'];

    final parsed = (list is List)
        ? list.whereType<Map>().map((e) {
      final map = _stringKeyedMap(e);
      return CommunityItem.fromApiJson(map);
    }).toList()
        : <CommunityItem>[];
    return parsed;
  }

  @override
  Future<bool> createGroup({
    required int type,
    required String name,
    required String description
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic> {
        "type": type,
        "user_id": userId,
        "name": name,
        "description": description
      };
    final data = await _post('appCreateGroup', post);
    final sub = await subUnSub(action: 1, groupId: toInt(data['data']['group_id']));
    return _isSuccess(data) && sub;
  }

  @override
  Future<bool> subUnSub({
    required int action,
    required int groupId
  }) async {
    final List<int> actions = [1, 2];
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    if (!actions.any((e) => e == action )) throw Exception('Некорректный action');
    final post = <String, dynamic>{
      "action": action,
      "group_id": groupId,
      "user_id": userId
    };
    final body = await _post('appGroupUserSubscribe', post);
    return _isSuccess(body);
  }
}
