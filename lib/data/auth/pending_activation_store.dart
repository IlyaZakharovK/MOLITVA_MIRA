import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingActivation {
  final String email;
  final bool isAccountActivation;
  const PendingActivation(this.email, this.isAccountActivation);
}

class PendingActivationStore {
  PendingActivationStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kEmail = 'pending_activation_email';
  static const _kIsAccount = 'pending_activation_is_account';

  Future<void> setPending({
    required String email,
    required bool isAccountActivation,
  }) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kIsAccount, value: isAccountActivation ? '1' : '0');
  }

  Future<PendingActivation?> readPending() async {
    final email = await _storage.read(key: _kEmail);
    if (email == null || email.isEmpty) return null;

    final flag = await _storage.read(key: _kIsAccount);
    final isAccount = (flag ?? '1') == '1';
    return PendingActivation(email, isAccount);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kIsAccount);
  }
}
