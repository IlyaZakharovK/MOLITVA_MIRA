import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalStore {
  AuthLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token'; // user_id (int) as string
  static const _kEmail = 'auth_email';
  static const _kRegistered = 'auth_registered'; // "1"/"0"

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: _kToken);
    } else {
      await _storage.write(key: _kToken, value: token);
    }
  }

  Future<int?> getToken() async {
    try {
      final tokenString = await _storage.read(key: _kToken);
      if (tokenString == null || tokenString.isEmpty) {
        return null;
      }
      return int.tryParse(tokenString);
    } catch (e) {
      // ignore
      return null;
    }
  }

  Future<void> setEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _storage.delete(key: _kEmail);
    } else {
      await _storage.write(key: _kEmail, value: email);
    }
  }

  Future<String?> getEmail() => _storage.read(key: _kEmail);

  Future<void> setRegistered(bool value) =>
      _storage.write(key: _kRegistered, value: value ? '1' : '0');

  Future<bool> getRegistered() async {
    final v = await _storage.read(key: _kRegistered);
    if (v == null) return true;
    return v == '1';
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kRegistered);
  }
}
