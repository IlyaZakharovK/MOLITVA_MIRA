import 'package:flutter/material.dart';

class BlueMenuDrawer extends StatelessWidget {
  final String? currentRoute;

  final VoidCallback onPrayerRequest;
  final VoidCallback onNews;
  final VoidCallback onCommunities;
  final VoidCallback onStreams;
  final VoidCallback onMyCommunities;
  final VoidCallback onMyStreams;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const BlueMenuDrawer({
    super.key,
    required this.currentRoute,
    required this.onPrayerRequest,
    required this.onNews,
    required this.onCommunities,
    required this.onStreams,
    required this.onMyCommunities,
    required this.onMyStreams,
    required this.onProfile,
    required this.onLogout,
  });

  static const _bg = Color(0xFF3F4F86);
  static const _active = Color(0xFF142B56);
  static const _text = Color(0xFFD6DCF3);
  static const _textActive = Colors.white;

  bool _isActive(String route) => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: _bg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 84,
              width: double.infinity,
              color: _bg,
              alignment: Alignment.center,
              child: const Text(
                'Молитва Мира',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuItem(
                    title: 'Запрос на молитву',
                    icon: Icons.add_circle_outline,
                    active: _isActive('/pray'),
                    onTap: onPrayerRequest,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Главная',
                    icon: Icons.article_outlined,
                    active: _isActive('/news'),
                    onTap: onNews,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Сообщества',
                    icon: Icons.group_outlined,
                    active: _isActive('/communities'),
                    onTap: onCommunities,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Трансляции',
                    icon: Icons.videocam_outlined,
                    active: _isActive('/streams'),
                    onTap: onStreams,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),

                  _MenuItem(
                    title: 'Мои сообщества',
                    icon: Icons.group_add_outlined,
                    active: _isActive('/my_communities'),
                    onTap: onMyCommunities,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Мои трансляции',
                    icon: Icons.video_library_outlined,
                    active: _isActive('/pray_history'),
                    onTap: onMyStreams,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Профиль',
                    icon: Icons.account_circle_outlined,
                    active: _isActive('/profile'),
                    onTap: onProfile,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),

                  _MenuItem(
                    title: 'Выход',
                    icon: Icons.logout_outlined,
                    active: false,
                    onTap: onLogout,
                    activeColor: _active,
                    textColor: _text,
                    textActiveColor: _textActive,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  final Color activeColor;
  final Color textColor;
  final Color textActiveColor;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
    required this.textColor,
    required this.textActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? activeColor : Colors.transparent;
    final fg = active ? textActiveColor : textColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: bg,
        child: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
