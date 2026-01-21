import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';

class SessionCookieStore {
  SessionCookieStore(this._jar);

  final CookieJar _jar;
  final Uri _baseUri = Uri.parse('https://molitvamira.ru/');

  Future<void> writeSession(String sessionId) async {
    final cookie = Cookie('PHPSESSID', sessionId)
      ..path = '/'
      ..httpOnly = true;
    await _jar.saveFromResponse(_baseUri, [cookie]);
  }

  Future<String?> readSession() async {
    final cookies = await _jar.loadForRequest(_baseUri);
    for (final c in cookies) {
      if (c.name == 'PHPSESSID' && c.value.isNotEmpty) return c.value;
    }
    return null;
  }

  Future<void> clear() => _jar.deleteAll();
}
