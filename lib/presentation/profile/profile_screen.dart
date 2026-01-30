import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile/profile_model.dart';
import '../../domain/profile/profile_role.dart';
import '../shell/app_shell.dart';
import '../widgets/top_bar.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _templeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rectorNameCtrl = TextEditingController();
  final _rectorPhoneCtrl = TextEditingController();

  // Пока не подключили getDioceses -> храним строку.
  // На API сейчас приходит dioceses_id, но отображаем как строку.
  String _eparchy = '';

  bool _filledOnce = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _templeNameCtrl.dispose();
    _addressCtrl.dispose();
    _rectorNameCtrl.dispose();
    _rectorPhoneCtrl.dispose();
    super.dispose();
  }

  void _fill(ProfileModel p) {
    _fullNameCtrl.text = p.fullName;
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phone;

    _templeNameCtrl.text = p.templeName;
    _addressCtrl.text = p.address;
    _rectorNameCtrl.text = p.rectorName;
    _rectorPhoneCtrl.text = p.rectorPhone;

    _eparchy = p.eparchy;
    _filledOnce = true;
  }

  ProfileModel _collect(ProfileModel base) {
    return base.copyWith(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      templeName: _templeNameCtrl.text.trim(),
      eparchy: _eparchy.trim(),
      address: _addressCtrl.text.trim(),
      rectorName: _rectorNameCtrl.text.trim(),
      rectorPhone: _rectorPhoneCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Мой профиль'),

            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () {
                    _filledOnce = false;
                    ref.read(profileControllerProvider.notifier).load();
                  },
                ),
                data: (profile) {
                  if (!_filledOnce) _fill(profile);

                  // Админ отображается как обычный профиль (как мирянин),
                  // чтобы UI не ломался.
                  final role = profile.role;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          _RoleChip(
                            role: role,
                          ),

                          const SizedBox(height: 16),

                          if (role == ProfileRole.layman || role == ProfileRole.admin) ...[
                            _Label('Имя'),
                            _Input(controller: _fullNameCtrl),
                            const SizedBox(height: 10),

                            _Label('Email'),
                            _Input(controller: _emailCtrl),
                            const SizedBox(height: 10),

                            _Label('Ваш телефон'),
                            _Input(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                          ] else if (role == ProfileRole.temple) ...[
                            _Label('Епархия'),
                            _ReadOnlyField(
                              value: _eparchy.isEmpty ? 'Не указана' : _eparchy,
                              onTap: () {
                                // позже подключим getDioceses + поиск.
                                // сейчас просто read-only.
                              },
                            ),
                            const SizedBox(height: 10),

                            _Label('Адрес Храма/Монастыря'),
                            _Input(controller: _addressCtrl),
                            const SizedBox(height: 10),

                            _Label('Телефон настоятеля'),
                            _Input(
                              controller: _rectorPhoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 10),

                            _Label('Название Храма/Монастыря'),
                            _Input(controller: _templeNameCtrl),
                            const SizedBox(height: 10),

                            _Label('Имя настоятеля'),
                            _Input(controller: _rectorNameCtrl),
                            const SizedBox(height: 10),
                          ] else ...[
                            // clergy
                            _Label('Имя'),
                            _Input(controller: _fullNameCtrl),
                            const SizedBox(height: 10),

                            _Label('Название Храма/Монастыря'),
                            _Input(controller: _templeNameCtrl),
                            const SizedBox(height: 10),

                            _Label('Имя настоятеля'),
                            _Input(controller: _rectorNameCtrl),
                            const SizedBox(height: 10),

                            _Label('Епархия'),
                            _ReadOnlyField(
                              value: _eparchy.isEmpty ? 'Не указана' : _eparchy,
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),

                            _Label('Адрес Храма/Монастыря'),
                            _Input(controller: _addressCtrl),
                            const SizedBox(height: 10),

                            _Label('Телефон настоятеля'),
                            _Input(
                              controller: _rectorPhoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 10),
                          ],

                          const SizedBox(height: 18),

                          InkWell(
                            onTap: () {
                              // TODO: change password flow
                            },
                            child: const Text(
                              'Сменить пароль',
                              style: TextStyle(
                                color: Color(0xFFFF6A00),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 34),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF3F4F86),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () async {
                                final updated = _collect(profile);
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .save(updated);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Сохранено')),
                                );
                              },
                              child: const Text('Сохранить'),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Не удалось загрузить профиль\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final ProfileRole role;

  const _RoleChip({required this.role,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3F4F86), width: 1),
      ),
      child: Text(
        role.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black45),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _ReadOnlyField({
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
