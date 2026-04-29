import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_reset_scope.dart';
import '../../providers.dart';
import '../widgets/blue_menu_drawer.dart';

class AppShell extends ConsumerStatefulWidget {
  final bool translation;
  final Widget child;

  final dynamic ctrl;

  const AppShell({
    super.key,
    required this.child,
    this.translation = false,
    this.ctrl,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _confirmOpen = false;

  Future<bool> _confirmLeaveTranslation(BuildContext context) async {
    if (_confirmOpen) return false;
    _confirmOpen = true;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Выход'),
        content: const Text('Вы действительно желаете выйти из трансляции?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    _confirmOpen = false;
    return res ?? false;
  }

  Future<void> _safeExitTranslation() async {
    try {
      final v = widget.ctrl;
      if (v != null) {
        final r = v.exit();
        if (r is Future) await r;
      }
    } catch (_) {}
  }

  Future<void> _go(BuildContext context, String route) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (ModalRoute.of(context)?.settings.name == route) return;

    if (widget.translation) {
      final ok = await _confirmLeaveTranslation(context);
      if (!ok) return;

      await _safeExitTranslation();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(route);
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  void _invalidateAppScopedProviders() {
    ref.invalidate(authControllerProvider);
    ref.invalidate(authRepositoryProvider);
    ref.invalidate(authLocalStoreProvider);
    ref.invalidate(sessionCookieStoreProvider);
    ref.invalidate(pendingActivationStoreProvider);

    ref.invalidate(diocesesRepositoryProvider);
    ref.invalidate(diocesesProvider);

    ref.invalidate(notificationsRepositoryProvider);
    ref.invalidate(communitiesRepositoryProvider);
    ref.invalidate(prayerRequestRepositoryProvider);
    ref.invalidate(prayerRequestRepositoryProvider);
    ref.invalidate(newsRepositoryProvider);
    ref.invalidate(communityDetailsRepositoryProvider);
    ref.invalidate(uploadRepositoryProvider);
    ref.invalidate(profileRepositoryProvider);
    ref.invalidate(prayRepositoryProvider);
    ref.invalidate(helpChatRepositoryProvider);
    ref.invalidate(registrationManagerProvider);
  }

  void _clearFlutterCaches() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }

  Future<void> _logout(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (widget.translation) {
      final ok = await _confirmLeaveTranslation(context);
      if (!ok) return;

      await _safeExitTranslation();
      if (!mounted) return;
    }

    await ref.read(authControllerProvider.notifier).logout();

    _clearFlutterCaches();

    if (!mounted) return;
    AppResetScope.restartApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      drawer: BlueMenuDrawer(
        currentRoute: currentRoute,
        onPrayerRequest: () => _go(context, '/pray'),
        onNews: () => _go(context, '/news'),
        onCommunities: () => _go(context, '/communities'),
        onStreams: () => _go(context, '/streams'),
        onMyStreams: () => _go(context, '/my_streams'),
        onMyCommunities: () => _go(context, '/my_communities'),
        onProfile: () => _go(context, '/profile'),
        onModerate: () => _go(context, '/moderate'),
        onPrays: () => _go(context, '/prays'),
        onLogout: () => _logout(context),
        onHelp: () => _go(context, '/help'),
      ),
      body: widget.child,
    );
  }
}