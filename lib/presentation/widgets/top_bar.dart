import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'burger_button.dart';
import '../profile/profile_controller.dart';

class TopBar extends StatelessWidget {
  final String title;
  final bool translation;
  final ctrl;

  const TopBar({required this.title, this.translation = false, this.ctrl});

  void _go(BuildContext context, String route) {
    if (translation){
      ctrl.exit();
    }
    Navigator.of(context).popAndPushNamed(route);
  }

  Widget _buildProfileButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(profileControllerProvider);
        final avatarUrl = async.valueOrNull?.avatarUrl ?? '';

        final hasAvatar = avatarUrl.trim().isNotEmpty;
        final url = hasAvatar ? avatarUrl : '';

        return InkWell(
          onTap: () => _go(context, '/profile'),
          child: hasAvatar
              ? SizedBox(
            width: 35,
            height: 35,
            child: ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_circle_outlined,
                  color: Color(0xFF3F4F86),
                  size: 35,
                ),
              ),
            ),
          )
              : const Icon(
            Icons.account_circle_outlined,
            color: Color(0xFF3F4F86),
            size: 35,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFFF6F7F9),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => BurgerButton(
              color: Colors.black87,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _buildProfileButton(context),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
