import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../widgets/blue_menu_drawer.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onLogout: () {
          Navigator.of(context).pop();
          ref.read(authControllerProvider.notifier).logout().then((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          });
        },
      ),
      body: child,
    );
  }
}
