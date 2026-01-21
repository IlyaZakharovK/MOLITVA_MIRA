import 'package:dio/dio.dart';

import '../../api/cookieStore.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/user_session.dart';
import 'auth_local_store.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required Dio dio,
    required SessionCookieStore cookieStore,
    required AuthLocalStore localStore,
  })  : _dio = dio,
        _cookies = cookieStore,
        _local = localStore;

  final Dio _dio;
  final SessionCookieStore _cookies;
  final AuthLocalStore _local;

  UserSession? _session;

  static const _type = 'application';
  static const _pass = 'f92R*#eiDF82W@#k2WO';

  @override
  UserSession? get currentSession => _session;

  Future<Map<String, dynamic>> _post(String method, Map<String, dynamic> data) async {
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
      throw const ValidationFailure('Некорректный ответ сервера');
    }
    return body;
  }

  bool _isSuccess(Map<String, dynamic> body) => (body['status'] ?? '').toString() == 'success';

  String _desc(Map<String, dynamic> body) => (body['description'] ?? '').toString();

  AuthFailure _mapFailure(String description) {
    final d = description.toLowerCase();
    if (d.contains('неверн') || d.contains('парол') || d.contains('email')) {
      // грубая эвристика
      return const InvalidCredentialsFailure();
    }
    if (d.contains('уже') && (d.contains('зарегистр') || d.contains('существ'))) {
      return const EmailAlreadyUsedFailure();
    }
    if (d.contains('коротк') || d.contains('минимум')) {
      return const WeakPasswordFailure();
    }
    return ValidationFailure(description);
  }

  @override
  Future<UserSession?> restoreSession() async {
    final token = await _local.getToken();
    final email = await _local.getEmail();

    if (token == null) return null;

    // если cookie-jar пустой (например после очистки), восстановим из token
    final jarSession = await _cookies.readSession();
    if (jarSession == null || jarSession.isEmpty) {
      await _cookies.writeSession(token.toString());
    }

    final safeEmail = (email ?? '').trim().toLowerCase();
    _session = UserSession(
      userId: safeEmail.isEmpty ? 'unknown' : safeEmail,
      email: safeEmail,
      accessToken: token.toString(),
    );
    return _session;
  }

  @override
  Future<String?> restorePendingActivationEmail() async {
    final email = await _local.getEmail();
    final registered = await _local.getRegistered();
    if (email == null || email.isEmpty) return null;
    if (registered == false) return email;
    return null;
  }

  @override
  Future<UserSession> login({required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw const ValidationFailure('Email обязателен');

    try {
      final body = await _post('appLoginAccount', {
        'email': normalized,
        'password': password,
      });

      if (!_isSuccess(body)) {
        throw _mapFailure(_desc(body));
      }

      final data = body['data'];
      final raw = (data is Map) ? data['user_id'] : null;

      final userId = (raw is num) ? raw.toInt() : int.tryParse('$raw');
      if (userId == null) {
        throw const ValidationFailure('Сервер не вернул user_id');
      }

      final token = userId.toString();

      await _local.setToken(token);
      await _local.setEmail(normalized);
      await _local.setRegistered(true);

      _session = UserSession(
        userId: token,
        email: normalized,
        accessToken: token,
      );
      return _session!;
    } on DioException {
      throw const ValidationFailure('Ошибка сети. Попробуйте позже');
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password1,
    required String password2,
    required int agree,
    int phone = 0,
    int type = 2,
    int diocesesId = 0,
    String hramName = '',
    String hramAddress = '',
    String nastName = '',
    int nastPhone = 0,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw const ValidationFailure('Email обязателен');

    try {
      final body = await _post('appRegisterAccount', {
        'name': name.trim(),
        'email': normalized,
        'password1': password1,
        'password2': password2,
        'phone': phone,
        'type': type,
        'dioceses_id': diocesesId,
        'hram_name': hramName,
        'hram_address': hramAddress,
        'nast_name': nastName,
        'nast_phone': nastPhone,
        'agree': agree,
      });

      if (!_isSuccess(body)) {
        throw _mapFailure(_desc(body));
      }

      // регистрация не логинит. сохраняем email + registered=false
      await _local.setEmail(normalized);
      await _local.setRegistered(false);

      // на всякий случай: токен/сессия чистые
      await _local.setToken(null);
      await _cookies.clear();
      _session = null;
    } on DioException {
      throw const ValidationFailure('Ошибка сети. Попробуйте позже');
    }
  }

  @override
  Future<void> activateEmail({
    required String email,
    required String activationCode,
    required String method,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw const ValidationFailure('Email обязателен');

    try {
      final body = await _post(method, {
        'email': normalized,
        'activation_code': activationCode,
      });

      if (!_isSuccess(body)) {
        throw _mapFailure(_desc(body));
      }

      await _local.setRegistered(true);
      await _local.setEmail(normalized);
    } on DioException {
      throw const ValidationFailure('Ошибка сети. Попробуйте позже');
    }
  }

  @override
  Future<void> restoreAccess({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) throw const ValidationFailure('Email обязателен');

    try {
      final body = await _post('appRecoverAccount', {
        'email': normalized,
        'agree': 1,
      });

      if (!_isSuccess(body)) {
        throw _mapFailure(_desc(body));
      }
    } on DioException {
      throw const ValidationFailure('Ошибка сети. Попробуйте позже');
    }
  }

  @override
  Future<void> logout() async {
    await _cookies.clear();
    await _local.clear();
    _session = null;
  }
}
