import '../../domain/auth/user_session.dart';

class AuthState {
  static const _unset = Object();

  final bool isLoading;
  final UserSession? session;

  final String? pendingActivationEmail;
  final bool? pendingActivationIsAccount; // true/false

  final String? errorMessage;

  const AuthState({
    required this.isLoading,
    required this.session,
    required this.pendingActivationEmail,
    required this.pendingActivationIsAccount,
    required this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(
    isLoading: false,
    session: null,
    pendingActivationEmail: null,
    pendingActivationIsAccount: null,
    errorMessage: null,
  );

  AuthState copyWith({
    bool? isLoading,
    Object? session = _unset,
    Object? pendingActivationEmail = _unset,
    Object? pendingActivationIsAccount = _unset,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session == _unset ? this.session : session as UserSession?,
      pendingActivationEmail: pendingActivationEmail == _unset
          ? this.pendingActivationEmail
          : pendingActivationEmail as String?,
      pendingActivationIsAccount: pendingActivationIsAccount == _unset
          ? this.pendingActivationIsAccount
          : pendingActivationIsAccount as bool?,
      errorMessage: errorMessage,
    );
  }
}
