sealed class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Неверный email или пароль');
}

class EmailAlreadyUsedFailure extends AuthFailure {
  const EmailAlreadyUsedFailure() : super('Этот email уже зарегистрирован');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('Пароль слишком короткий (минимум 6 символов)');
}

class ValidationFailure extends AuthFailure {
  const ValidationFailure(super.message);
}
