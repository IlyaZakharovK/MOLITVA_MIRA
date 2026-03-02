import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile/profile_model.dart';
import '../../domain/profile/profile_role.dart';
import '../../helper/image_helper.dart';
import '../shell/app_shell.dart';
import '../widgets/app_message_bar.dart';
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

  bool _uploadingAvatar = false;

  // ✅ для cache-busting URL аватара
  int _avatarBust = DateTime.now().millisecondsSinceEpoch;

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

  Future<void> _hardImageRefresh() async {
    // ✅ сбрасываем кэш картинок
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    // ✅ меняем bust, чтобы URL стал новым
    setState(() => _avatarBust = DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _onRefresh() async {
    _filledOnce = false;
    await _hardImageRefresh();
    await ref.read(profileControllerProvider.notifier).refresh();
  }

  Future<void> _onPickAvatar(ProfileModel profile) async {
    if (_uploadingAvatar) return;

    final bytes = await pickImageBytes(context);
    if (bytes == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final res =
      await ref.read(profileControllerProvider.notifier).uploadAvatar(bytes);

      // ✅ после загрузки — принудительно обновляем отображение (кэш + bust + refresh)
      _filledOnce = false;
      await _hardImageRefresh();
      await ref.read(profileControllerProvider.notifier).refresh();

      final status = (res['status'] ?? '').toString();
      final desc = (res['description'] ?? '').toString();

      showAppMessageBar(
        context,
        status.isEmpty ? 'Аватар загружен' : '$status: $desc',
      );
    } catch (e) {
      showAppMessageBar(
        context,
        'Ошибка загрузки: $e',
        brand: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profileControllerProvider);

    return AppShell(
      child: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'Профиль'),
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
                  final avatarUrl = profile.avatarUrl;

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),

                            _ProfileHeaderCard(
                              avatarUrl: avatarUrl,
                              avatarBust: _avatarBust,
                              uploading: _uploadingAvatar,
                              onTapCamera: () => _onPickAvatar(profile),
                              fullName: profile.fullName,
                              roleLabel: role.label,
                            ),

                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Ваши данные',
                              child: Column(
                                children: [
                                  _Label('Имя'),
                                  _Input(controller: _fullNameCtrl, enabled: false),
                                  const SizedBox(height: 10),

                                  _Label('E-mail'),
                                  _Input(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 10),

                                  if (role == ProfileRole.layman ||
                                      role == ProfileRole.admin) ...[
                                    _Label('Телефон'),
                                    _Input(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      enabled: false,
                                    ),
                                  ] else if (role == ProfileRole.temple) ...[
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

                                    _Label('Название Храма/Монастыря'),
                                    _Input(controller: _templeNameCtrl, enabled: false),
                                    const SizedBox(height: 10),

                                    _Label('Имя настоятеля'),
                                    _Input(controller: _rectorNameCtrl, enabled: false),
                                  ] else ...[
                                    // clergy
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
                                  ],

                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
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

class _ProfileHeaderCard extends StatelessWidget {
  final String avatarUrl;
  final int avatarBust;
  final bool uploading;
  final VoidCallback onTapCamera;
  final String fullName;
  final String roleLabel;

  const _ProfileHeaderCard({
    required this.avatarUrl,
    required this.avatarBust,
    required this.uploading,
    required this.onTapCamera,
    required this.fullName,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final raw = avatarUrl.trim();
    final hasAvatar = raw.isNotEmpty;

    final displayUrl = !hasAvatar
        ? ''
        : (raw.contains('?') ? '$raw&v=$avatarBust' : '$raw?v=$avatarBust');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                key: ValueKey(displayUrl),
                radius: 54,
                backgroundColor: const Color(0xFFF0F2F4),
                backgroundImage: hasAvatar ? NetworkImage(displayUrl) : null,
                child: hasAvatar
                    ? null
                    : const Icon(Icons.person_outline, size: 44, color: Colors.black38),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: uploading ? null : onTapCamera,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: uploading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.photo_camera, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            roleLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3F4F86),
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
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