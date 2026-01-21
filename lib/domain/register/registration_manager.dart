class RegistrationManager {
  Future<void> submit(Map<String, dynamic> payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Тут позже будет вызов API
  }
}
