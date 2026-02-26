import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../presentation/community_details/community_details_screen.dart';

class DeepLinkService {
  DeepLinkService(this.navigatorKey);
  String? _lastHandledKey;

  final GlobalKey<NavigatorState> navigatorKey;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    debugPrint('[DEEPLINK] init()');

    final Uri? initial = await _appLinks.getInitialLink();
    debugPrint('[DEEPLINK] initial=$initial');
    if (initial != null) _handle(initial);

    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('[DEEPLINK] stream=$uri');
      _handle(uri);
    });
  }

  void dispose() => _sub?.cancel();

  void _handle(Uri uri) {
    final key = uri.toString();
    if (_lastHandledKey == key) {
      debugPrint('[DEEPLINK] skip duplicate=$key');
      return;
    }
    _lastHandledKey = key;
    debugPrint('[DEEPLINK] handle=$key');

    if (uri.host != 'molitvamira.ru' && uri.host != 'www.molitvamira.ru') {
      debugPrint('[DEEPLINK] в пролете uri.host');
      return;
    }
    final p = uri.path.toLowerCase();
    final isSupported = p.startsWith('/translations') || p.startsWith('/groups');

    debugPrint('[DEEPLINK]  ${isSupported.toString()}');

    if (!isSupported) {
      debugPrint('[DEEPLINK] в пролете из-за префикса');
      return;
    }

    final invite = uri.queryParameters['invite'];
    final id = uri.queryParameters['id'];
    debugPrint('[DEEPLINK] invite=$invite');
    if (uri.path.toLowerCase().startsWith('/translations')) {
      if ((invite == null || invite.isEmpty) && (id != null)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('[DEEPLINK] navigate -> /live_stream invite=$invite');
          navigatorKey.currentState?.pushReplacementNamed(
            '/live_stream',
            arguments: {'translationID': id, 'invited': false},
          );
        });
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[DEEPLINK] navigate -> /live_stream invite=$invite');
        navigatorKey.currentState?.pushReplacementNamed(
          '/live_stream',
          arguments: {'invite': invite, 'invited': true},
        );
      });
    }
    else if (p.startsWith('/groups')) {
      final invite = uri.queryParameters['invite'];
      final idStr = uri.queryParameters['id'];
      final idInt = int.tryParse(idStr ?? '');

      final invited = invite != null && invite.isNotEmpty;

      if (idInt == null && !invited) {
        debugPrint('[DEEPLINK] groups: bad params id=$idStr invite=$invite');
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[DEEPLINK] navigate -> /groups id=${idInt ?? 0} invited=$invited invite=${invite ?? ''}');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          CommunityDetailsScreen.routeName,
              (route) => false,
          arguments: {
            'communityID': idInt ?? 0,
            'invited': invited,
            'invite': invite ?? '',
          },
        );
      });
    }
  }
}
