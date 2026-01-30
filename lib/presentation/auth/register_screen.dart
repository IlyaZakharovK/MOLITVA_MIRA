import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dioceses/diocese.dart';
import '../../providers.dart';
import '../common/slide_captcha_sheet.dart';
import '../widgets/agreeDialog.dart';
import '../widgets/agreement_block.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/input.dart';
import '../widgets/label.dart';

enum RegisterType { layman, clergy, temple }

extension RegisterTypeUi on RegisterType {
  String get title => switch (this) {
    RegisterType.layman => 'Мирянин',
    RegisterType.clergy => 'Священнослужитель',
    RegisterType.temple => 'Храм/Монастырь',
  };
}

enum _LegalDoc { privacy, agreement }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  RegisterType _type = RegisterType.layman;
  Diocese? _diocese;

  final _fullNameCtrl = TextEditingController();
  final _templeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rectorNameCtrl = TextEditingController();
  final _rectorPhoneCtrl = TextEditingController();

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  bool _agreed = false;

  final Map<String, String?> _errors = {};
  bool _navigated = false;

  final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool _isValidEmail(String s) => _emailRe.hasMatch(s.trim());

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _templeNameCtrl.dispose();
    _addressCtrl.dispose();
    _rectorNameCtrl.dispose();
    _rectorPhoneCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  void _setError(String key, String? message) => _errors[key] = message;

  void _clearField(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

  void _onTypeChanged(RegisterType v) {
    setState(() {
      _type = v;
      _diocese = null;
      _errors.clear();
      _passwordCtrl.clear();
      _password2Ctrl.clear();
    });
  }

  bool _validateAndShow() {
    _errors.clear();

    bool ok = true;
    String? firstError;

    bool req(String key, String value, String message) {
      if (value.trim().isEmpty) {
        _setError(key, message);
        firstError ??= message;
        return false;
      }
      return true;
    }

    void validateEmail() {
      final email = _emailCtrl.text.trim();
      if (!req('email', email, 'Введите e-mail')) {
        ok = false;
        return;
      }
      if (!_isValidEmail(email)) {
        _setError('email', 'E-mail введен не корректно');
        firstError ??= 'E-mail введен не корректно';
        ok = false;
      }
    }

    void validatePasswordPair() {
      final p1 = _passwordCtrl.text;
      final p2 = _password2Ctrl.text;

      if (!req('password', p1, 'Введите пароль')) ok = false;
      if (!req('password2', p2, 'Введите пароль повторно')) ok = false;

      if (p1.isNotEmpty && p2.isNotEmpty && p1 != p2) {
        _setError('password2', 'Пароли не совпадают');
        firstError ??= 'Пароли не совпадают';
        ok = false;
      }
    }

    switch (_type) {
      case RegisterType.layman:
        ok = req('fullName', _fullNameCtrl.text, 'Введите имя') && ok;
        validateEmail();
        validatePasswordPair();
        break;

      case RegisterType.clergy:
        ok = req('fullName', _fullNameCtrl.text, 'Введите имя') && ok;
        validateEmail();
        validatePasswordPair();

        if (_diocese == null) {
          _setError('eparchy', 'Выберите епархию');
          firstError ??= 'Выберите епархию';
          ok = false;
        }

        ok =
            req('templeName', _templeNameCtrl.text, 'Введите храм/монастырь') &&
            ok;
        ok = req('address', _addressCtrl.text, 'Введите адрес') && ok;
        ok =
            req('rectorName', _rectorNameCtrl.text, 'Введите имя настоятеля') &&
            ok;
        ok =
            req(
              'rectorPhone',
              _rectorPhoneCtrl.text,
              'Введите телефон настоятеля',
            ) &&
            ok;
        break;

      case RegisterType.temple:
        validateEmail();
        validatePasswordPair();

        if (_diocese == null) {
          _setError('eparchy', 'Выберите епархию');
          firstError ??= 'Выберите епархию';
          ok = false;
        }

        ok = req('templeName', _templeNameCtrl.text, 'Введите название') && ok;
        ok = req('address', _addressCtrl.text, 'Введите адрес') && ok;
        ok =
            req('rectorName', _rectorNameCtrl.text, 'Введите имя настоятеля') &&
            ok;
        break;
    }

    if (!_agreed) {
      _setError('agreement', 'Примите пользовательское соглашение');
      firstError ??= 'Примите пользовательское соглашение';
      ok = false;
    }

    setState(() {});

    if (firstError != null) {
      showAppMessageBar(context, firstError!);
      return false;
    }
    return ok;
  }

  Future<Diocese?> _pickDiocese(BuildContext context) {
    return showModalBottomSheet<Diocese>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiocesePickerSheet(selectedId: _diocese?.id),
    );
  }

  Future<void> _submit() async {
    if (!_validateAndShow()) return;

    final ok = await showSlideCaptchaSheet(context);
    if (!ok) return;

    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password1: _passwordCtrl.text,
          password2: _password2Ctrl.text,
          agree: _agreed ? 1 : 0,
          type: switch (_type) {
            RegisterType.layman => 1,
            RegisterType.clergy => 2,
            RegisterType.temple => 3,
          },
          phone:
              int.tryParse(_phoneCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
          diocesesId: _diocese?.id ?? 0,
          hramName: _templeNameCtrl.text.trim(),
          hramAddress: _addressCtrl.text.trim(),
          nastName: _rectorNameCtrl.text.trim(),
          nastPhone:
              int.tryParse(
                _rectorPhoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
              ) ??
              0,
        );
  }

  void _navigateOnce(VoidCallback go) {
    if (_navigated) return;
    _navigated = true;
    go();
  }

  void _openDoc(_LegalDoc doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalDocSheet(doc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;

    // ✅ controller error → bar
    ref.listen(authControllerProvider.select((s) => s.errorMessage), (
      prev,
      next,
    ) {
      if (!context.mounted) return;
      if (next != null && next.isNotEmpty && next != prev) {
        showAppMessageBar(context, next);
      }
    });

    // ✅ если появился pendingActivation — идём на подтверждение
    ref.listen(authControllerProvider, (prev, next) {
      if (!context.mounted) return;
      if (prev?.pendingActivationEmail == null &&
          next.pendingActivationEmail != null) {
        _navigateOnce(() {
          Navigator.of(
            context,
          ).pushReplacementNamed('/activate', arguments: true);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'Молитва мира',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/png/pray_hands.png',
                    height: 84,
                    width: 84,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Регистрация',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RadioRow(
                          value: RegisterType.layman,
                          groupValue: _type,
                          title: RegisterType.layman.title,
                          onChanged: _onTypeChanged,
                        ),
                        _RadioRow(
                          value: RegisterType.clergy,
                          groupValue: _type,
                          title: RegisterType.clergy.title,
                          onChanged: _onTypeChanged,
                        ),
                        _RadioRow(
                          value: RegisterType.temple,
                          groupValue: _type,
                          title: RegisterType.temple.title,
                          onChanged: _onTypeChanged,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_type == RegisterType.layman) ..._buildLayman(),
                  if (_type == RegisterType.clergy) ..._buildClergy(),
                  if (_type == RegisterType.temple) ..._buildTemple(),

                  const SizedBox(height: 12),
                  AgreementBlock(
                    isChecked: _agreed,
                    isError: _errors['agreement'] != null,
                    onChanged: (v) => setState(() => _agreed = v),
                    onOpenPrivacy: () {
                      final dio = ref.read(dioProvider);
                      showAgreeDialog(
                        context,
                        dio: dio,
                        docType: AgreeDocType.privacy,
                      );
                    },
                    onOpenAgreement: () {
                      final dio = ref.read(dioProvider);
                      showAgreeDialog(
                        context,
                        dio: dio,
                        docType: AgreeDocType.terms,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: (loading) ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Если есть аккаунт, войдите в него',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 5),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).pushNamed('/'),
                      child: const Text('Вход'),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLayman() => [
    const Label('Ваше имя'),
    Input(
      controller: _fullNameCtrl,
      hint: '',
      error: _errors['fullName'],
      onChanged: (_) => _clearField('fullName'),
    ),
    const SizedBox(height: 10),

    const Label('E-mail'),
    Input(
      controller: _emailCtrl,
      hint: '',
      error: _errors['email'],
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => _clearField('email'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль'),
    Input(
      controller: _passwordCtrl,
      hint: '',
      error: _errors['password'],
      obscureText: true,
      onChanged: (_) => _clearField('password'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль повторно'),
    Input(
      controller: _password2Ctrl,
      hint: '',
      error: _errors['password2'],
      obscureText: true,
      onChanged: (_) => _clearField('password2'),
    ),
    const SizedBox(height: 10),

    const Label('Ваш телефон', needs: false),
    Input(
      controller: _phoneCtrl,
      hint: '',
      error: _errors['phone'],
      keyboardType: TextInputType.phone,
      onChanged: (_) => _clearField('phone'),
    ),
  ];

  List<Widget> _buildClergy() => [
    const Label('Ваше имя'),
    Input(
      controller: _fullNameCtrl,
      hint: '',
      error: _errors['fullName'],
      onChanged: (_) => _clearField('fullName'),
    ),
    const SizedBox(height: 10),

    const Label('E-mail'),
    Input(
      controller: _emailCtrl,
      hint: '',
      error: _errors['email'],
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => _clearField('email'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль'),
    Input(
      controller: _passwordCtrl,
      hint: '',
      error: _errors['password'],
      obscureText: true,
      onChanged: (_) => _clearField('password'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль повторно'),
    Input(
      controller: _password2Ctrl,
      hint: '',
      error: _errors['password2'],
      obscureText: true,
      onChanged: (_) => _clearField('password2'),
    ),
    const SizedBox(height: 10),

    const Label('Епархия'),
    _PickerField(
      text: _diocese?.name ?? '— Выберите епархию —',
      error: _errors['eparchy'],
      onTap: () async {
        final picked = await _pickDiocese(context);
        if (picked == null) return;
        setState(() {
          _diocese = picked;
          _errors.remove('eparchy');
        });
      },
    ),
    const SizedBox(height: 10),

    const Label('Название Храма/Монастыря'),
    Input(
      controller: _templeNameCtrl,
      hint: '',
      error: _errors['templeName'],
      onChanged: (_) => _clearField('templeName'),
    ),
    const SizedBox(height: 10),

    const Label('Адрес Храма/Монастыря'),
    Input(
      controller: _addressCtrl,
      hint: '',
      error: _errors['address'],
      onChanged: (_) => _clearField('address'),
    ),
    const SizedBox(height: 10),

    const Label('Имя настоятеля'),
    Input(
      controller: _rectorNameCtrl,
      hint: '',
      error: _errors['rectorName'],
      onChanged: (_) => _clearField('rectorName'),
    ),
    const SizedBox(height: 10),

    const Label('Телефон настоятеля'),
    Input(
      controller: _rectorPhoneCtrl,
      hint: '',
      error: _errors['rectorPhone'],
      keyboardType: TextInputType.phone,
      onChanged: (_) => _clearField('rectorPhone'),
    ),
  ];

  List<Widget> _buildTemple() => [
    const Label('E-mail'),
    Input(
      controller: _emailCtrl,
      hint: '',
      error: _errors['email'],
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => _clearField('email'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль'),
    Input(
      controller: _passwordCtrl,
      hint: '',
      error: _errors['password'],
      obscureText: true,
      onChanged: (_) => _clearField('password'),
    ),
    const SizedBox(height: 10),

    const Label('Пароль повторно'),
    Input(
      controller: _password2Ctrl,
      hint: '',
      error: _errors['password2'],
      obscureText: true,
      onChanged: (_) => _clearField('password2'),
    ),
    const SizedBox(height: 10),

    const Label('Ваш телефон', needs: false),
    Input(
      controller: _phoneCtrl,
      hint: '',
      error: _errors['phone'],
      keyboardType: TextInputType.phone,
      onChanged: (_) => _clearField('phone'),
    ),
    const SizedBox(height: 10),

    const Label('Епархия'),
    _PickerField(
      text: _diocese?.name ?? '— Выберите епархию —',
      error: _errors['eparchy'],
      onTap: () async {
        final picked = await _pickDiocese(context);
        if (picked == null) return;
        setState(() {
          _diocese = picked;
          _errors.remove('eparchy');
        });
      },
    ),
    const SizedBox(height: 10),

    const Label('Название Храма/Монастыря'),
    Input(
      controller: _templeNameCtrl,
      hint: '',
      error: _errors['templeName'],
      onChanged: (_) => _clearField('templeName'),
    ),
    const SizedBox(height: 10),

    const Label('Адрес Храма/Монастыря'),
    Input(
      controller: _addressCtrl,
      hint: '',
      error: _errors['address'],
      onChanged: (_) => _clearField('address'),
    ),
    const SizedBox(height: 10),

    const Label('Имя настоятеля'),
    Input(
      controller: _rectorNameCtrl,
      hint: '',
      error: _errors['rectorName'],
      onChanged: (_) => _clearField('rectorName'),
    ),
  ];
}

class _LegalDocSheet extends StatelessWidget {
  final _LegalDoc doc;

  const _LegalDocSheet({required this.doc});

  @override
  Widget build(BuildContext context) {
    final title = doc == _LegalDoc.privacy
        ? 'Политика конфиденциальности'
        : 'Пользовательское соглашение';

    final text = doc == _LegalDoc.privacy ? _privacyText : _agreementText;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3F4F86),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Заглушки. Позже заменим на HTML/asset/API.
const _privacyText =
    'Политика конфиденциальности\n\n(Текст будет добавлен позже)';
const _agreementText =
    'Пользовательское соглашение\n\n(Текст будет добавлен позже)';

class _RadioRow extends StatelessWidget {
  final RegisterType value;
  final RegisterType groupValue;
  final String title;
  final ValueChanged<RegisterType> onChanged;

  const _RadioRow({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<RegisterType>(
            value: value,
            groupValue: groupValue,
            onChanged: (_) => onChanged(value),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String? error;

  const _PickerField({
    required this.text,
    required this.onTap,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isError = error != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isError ? Colors.red : Colors.black26),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.search, size: 18, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _DiocesePickerSheet extends ConsumerStatefulWidget {
  final int? selectedId;

  const _DiocesePickerSheet({required this.selectedId});

  @override
  ConsumerState<_DiocesePickerSheet> createState() =>
      _DiocesePickerSheetState();
}

class _DiocesePickerSheetState extends ConsumerState<_DiocesePickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.toLowerCase().replaceAll('ё', 'е');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(diocesesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Выберите епархию',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Не удалось загрузить список\n$e',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(diocesesProvider),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    final q = _norm(_searchCtrl.text.trim());
                    final filtered = q.isEmpty
                        ? items
                        : items
                              .where((d) => _norm(d.name).contains(q))
                              .toList();

                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final d = filtered[i];
                        final selected = d.id == widget.selectedId;

                        return ListTile(
                          dense: true,
                          title: Text(d.name),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF3F4F86),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(d),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
