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

                  final role = profile.role;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          _RoleChip(role: role),

                          const SizedBox(height: 16),

                          // По ТЗ: e-mail самым первым и неактивным.
                          _Label('Email'),
                          _Input(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            enabled: false,
                          ),
                          const SizedBox(height: 10),

                          if (role == ProfileRole.layman ||
                              role == ProfileRole.admin) ...[
                            _Label('Имя'),
                            _Input(controller: _fullNameCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Ваш телефон'),
                            _Input(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              enabled: false,
                            ),
                          ] else if (role == ProfileRole.temple) ...[
                            _Label('Епархия'),
                            _ReadOnlyField(
                              enabled: false,
                              value: _eparchy.isEmpty ? 'Не указана' : _eparchy,
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),

                            _Label('Адрес Храма/Монастыря'),
                            _Input(controller: _addressCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Телефон настоятеля'),
                            _Input(
                              controller: _rectorPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              enabled: false,
                            ),
                            const SizedBox(height: 10),

                            _Label('Название Храма/Монастыря'),
                            _Input(controller: _templeNameCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Имя настоятеля'),
                            _Input(controller: _rectorNameCtrl, enabled: false),
                            const SizedBox(height: 10),
                          ] else ...[
                            // clergy
                            _Label('Имя'),
                            _Input(controller: _fullNameCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Название Храма/Монастыря'),
                            _Input(controller: _templeNameCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Имя настоятеля'),
                            _Input(controller: _rectorNameCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Епархия'),
                            _ReadOnlyField(
                              enabled: false,
                              value: _eparchy.isEmpty ? 'Не указана' : _eparchy,
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),

                            _Label('Адрес Храма/Монастыря'),
                            _Input(controller: _addressCtrl, enabled: false),
                            const SizedBox(height: 10),

                            _Label('Телефон настоятеля'),
                            _Input(
                              controller: _rectorPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              enabled: false,
                            ),
                            const SizedBox(height: 10),
                          ],

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

  const _RoleChip({required this.role});

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
  final bool enabled;

  const _Input({
    required this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      // Неактивно для ввода, но текст остаётся чёрным и читаемым.
      readOnly: !enabled,
      enabled: true,
      showCursor: enabled,
      enableInteractiveSelection: enabled,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF2F2F2),
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

    // Полностью гасим интерактивность: нет фокуса/клавиатуры/копирования.
    if (!enabled) return IgnorePointer(child: field);
    return field;
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  const _ReadOnlyField({
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? Colors.black26 : Colors.black12),
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
