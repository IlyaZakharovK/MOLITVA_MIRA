import 'package:cookie_jar/cookie_jar.dart' show PersistCookieJar;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class AppResetScope extends StatefulWidget {
  final Dio dio;
  final PersistCookieJar jar;
  final Widget child;

  const AppResetScope({
    super.key,
    required this.dio,
    required this.jar,
    required this.child,
  });

  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppResetScopeState>();
    state?.restartApp();
  }

  @override
  State<AppResetScope> createState() => _AppResetScopeState();
}

class _AppResetScopeState extends State<AppResetScope> {
  Key _scopeKey = UniqueKey();

  void restartApp() {
    setState(() {
      _scopeKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _scopeKey,
      overrides: [
        dioProvider.overrideWithValue(widget.dio),
        cookieJarProvider.overrideWithValue(widget.jar),
      ],
      child: widget.child,
    );
  }
}