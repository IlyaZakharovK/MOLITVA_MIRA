class UserSession {
  final String userId;
  final String email;
  final String accessToken;

  const UserSession({
    required this.userId,
    required this.email,
    required this.accessToken,
  });
}
