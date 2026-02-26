import 'package:dio/dio.dart';
import 'package:vsem_mirom/domain/community_details/community_details.dart';

import '../../domain/auth/auth_failure.dart';
import '../../domain/community_details/community_details_repository.dart';
import '../auth/auth_local_store.dart';

class APICommunityDetailsRepository implements CommunityDetailsRepository {
  APICommunityDetailsRepository({
    required Dio dio,
    required AuthLocalStore localStore,
  }) : _dio = dio,
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
    return s == 'success' || s == 'ok';
  }

  Map<String, dynamic> _stringKeyedMap(Map raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) => out[k.toString()] = v);
    return out;
  }

  @override
  Future<Community> fetchCommunity({required int id}) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{'group_id': id, 'user_id': userId};
    final body = await _post('appGroupData', post);
    final data = body['data'];
    final map = _stringKeyedMap(data);
    return Community.fromAPI(map);
  }

  @override
  Future<Community> fetchCommunityByInvite({required String invite}) async {
    final post = <String, dynamic>{'invite': invite};
    final body = await _post('appGetGroupByInvite', post);
    print('Вызвали fetchCommunityByInvite');
    final data = body['data'];
    final map = _stringKeyedMap(data);
    return fetchCommunity(id: map['id']);
  }

  @override
  Future<List<Post>> fetchMorePosts({
    required int id,
    required int limit,
    required int page,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{
      'group_id': id,
      'user_id': userId,
      'limit': limit,
      'page': page,
    };
    final body = await _post('appGetGroups', post);
    final listPosts = body['data']['posts'];
    final parsed = (listPosts is List)
        ? listPosts.whereType<Map>().map((e) {
            final map = _stringKeyedMap(e);
            return Post.fromAPI(map);
          }).toList()
        : <Post>[];
    return parsed;
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

  @override
  Future<bool> createPost({
    required int groupId,
    required int ownerId,
    required String title,
    required String message,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    if (userId != ownerId) throw Exception('Нет прав на создание постов');
    final post = <String, dynamic>{
      'group_id': groupId,
      'user_id': userId,
      'title': title,
      'message': message,
    };
    final body = await _post('appGroupCreatePost', post);
    return _isSuccess(body);
  }

  @override
  Future<bool> createComment({
    required int groupId,
    required int postId,
    required String message,
  }) async {
    final raw = await _local.getToken();
    if (raw == null) throw Exception('Нет user_id: не авторизован');
    final userId = int.tryParse(raw.toString());
    if (userId == null) throw Exception('Некорректный user_id');
    final post = <String, dynamic>{
      'group_id': groupId,
      'user_id': userId,
      'post_id': postId,
      'message': message,
    };
    final body = await _post('appGroupCreateComment', post);
    return _isSuccess(body);
  }
}
