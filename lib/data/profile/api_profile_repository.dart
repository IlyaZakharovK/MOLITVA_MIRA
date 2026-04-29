import 'package:dio/dio.dart';

import '../../data/auth/auth_local_store.dart';
import '../../domain/funcs/parseFuncs.dart';
import '../../domain/profile/profile_model.dart';
import '../../domain/profile/profile_repository.dart';
import '../../domain/profile/profile_role.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required Dio dio, required AuthLocalStore local})
    : _dio = dio,
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
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера');
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) =>
      (body['status'] ?? '').toString() == 'success';

  String _desc(Map<String, dynamic> body) =>
      (body['description'] ?? '').toString();

  ProfileRole _mapRole(dynamic typeId) {
    final id = (typeId is int)
        ? typeId
        : int.tryParse(typeId?.toString() ?? '') ?? 1;
    return switch (id) {
      1 => ProfileRole.layman,
      2 => ProfileRole.clergy,
      3 => ProfileRole.temple,
      4 => ProfileRole.admin,
      _ => ProfileRole.layman,
    };
  }

  String _numToPhone(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    if (s == '0') return '';
    return s;
  }

  @override
  Future<ProfileModel> load() async {
    final userId = await _local.getToken();
    if (userId == null) {
      throw Exception('Нет user_id: пользователь не авторизован');
    }

    final body = await _post('appGetUserData', {'user_id': userId});

    if (!_isSuccess(body)) {
      throw Exception(_desc(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Нет поля data у профиля');
    }

    final role = _mapRole(data['type_id']);
    final diocesesId = data['dioceses_id'];
    final diocesesStr = (diocesesId == null || diocesesId.toString() == '0')
        ? ''
        : 'ID $diocesesId';

    return ProfileModel(
      role: role,
      fullName: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: _numToPhone(data['phone']),
      templeName: (data['hram_name'] ?? '').toString(),
      address: (data['hram_address'] ?? '').toString(),
      rectorName: (data['nast_name'] ?? '').toString(),
      rectorPhone: _numToPhone(data['nast_phone']),
      eparchy: diocesesStr,
      avatarUrl: (data['avatarUrl'] ?? '').toString(),
      canBlass: toBool(data['can_bless'])
    );
  }

  @override
  Future<void> save(ProfileModel updated) async {
    return;
  }
}
