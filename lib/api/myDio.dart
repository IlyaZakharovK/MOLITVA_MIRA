import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:cookie_jar/cookie_jar.dart' show PersistCookieJar;
import 'package:cookie_jar/cookie_jar.dart' show FileStorage;
import 'package:path_provider/path_provider.dart';

Future<(Dio dio, PersistCookieJar jar)> buildDio() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://molitvamira.ru/api/',
    contentType: Headers.jsonContentType,
  ));

  final dir = await getApplicationDocumentsDirectory();
  final jar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));

  dio.interceptors.add(CookieManager(jar));
  return (dio, jar);
}
