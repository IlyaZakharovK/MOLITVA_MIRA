import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../widgets/blue_menu_drawer.dart';

class AppShell extends ConsumerStatefulWidget {
  final bool translation;
  final Widget child;

  /// Контроллер трансляции (у него есть exit()).
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
    // Закрыть drawer, чтобы диалог/навигация не конфликтовали
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Если и так на этом маршруте — ничего не делаем
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
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
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
        onLogout: () => _logout(context),
      ),
      body: widget.child,
    );
  }
}
