import 'user_session.dart';

abstract class AuthRepository {
  /// Восстановление сессии/статуса из хранилища при старте приложения
  Future<UserSession?> restoreSession();

  /// Если пользователь зарегистрировался, но не подтвердил email — вернём email
  Future<String?> restorePendingActivationEmail();

  Future<UserSession> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String name,
    required String email,
    required String password1,
    required String password2,
    required int agree,
    int phone,
    int type,
    int diocesesId,
    String hramName,
    String hramAddress,
    String nastName,
    int nastPhone,
  });

  Future<void> activateEmail({
    required String email,
    required String activationCode,
    required String method
  });

  Future<void> restoreAccess({required String email});

  Future<void> logout();

  /// null если не залогинен
  UserSession? get currentSession;
}
