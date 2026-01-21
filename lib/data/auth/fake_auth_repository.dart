import 'dart:math';

import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/user_session.dart';

class FakeAuthRepository implements AuthRepository {
  final Map<String, String> _users = {}; // email -> password
  UserSession? _session;
  String? _pendingActivationEmail;

  @override
  UserSession? get currentSession => _session;

  @override
  Future<UserSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _session;
  }

  @override
  Future<String?> restorePendingActivationEmail() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _pendingActivationEmail;
  }

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim().toLowerCase();
    final safeEmail = normalizedEmail.isEmpty ? 'user@pray.app' : normalizedEmail;

    _users.putIfAbsent(safeEmail, () => password);

    _pendingActivationEmail = null;
    _session = UserSession(
      userId: _genId(),
      email: safeEmail,
      accessToken: _fakeToken(),
    );
    return _session!;
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
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) throw const ValidationFailure('Email обязателен');
    if (!normalizedEmail.contains('@')) throw const ValidationFailure('Некорректный email');
    if (password1.length < 6) throw const WeakPasswordFailure();
    if (password1 != password2) throw const ValidationFailure('Пароли не совпадают');

    if (_users.containsKey(normalizedEmail)) throw const EmailAlreadyUsedFailure();

    _users[normalizedEmail] = password1;

    // регистрация -> требует активации
    _session = null;
    _pendingActivationEmail = normalizedEmail;
  }

  @override
  Future<void> activateEmail({
    required String email,
    required String activationCode,
    required String method,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _pendingActivationEmail = null;
  }

  @override
  Future<void> restoreAccess({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _session = null;
    _pendingActivationEmail = null;
  }

  String _genId() => (100000 + Random().nextInt(900000)).toString();

  String _fakeToken() =>
      List.generate(24, (_) => _chars[Random().nextInt(_chars.length)]).join();

  static const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
}
