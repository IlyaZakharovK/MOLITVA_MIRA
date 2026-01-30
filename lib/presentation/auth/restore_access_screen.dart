import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../common/slide_captcha_sheet.dart';
import '../widgets/agreeDialog.dart';
import '../widgets/agreement_block.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/input.dart';
import '../widgets/label.dart';

enum _LegalDoc { privacy, agreement }

class RestoreAccessScreen extends ConsumerStatefulWidget {
  const RestoreAccessScreen({super.key});

  @override
  ConsumerState<RestoreAccessScreen> createState() =>
      _RestoreAccessScreenState();
}

class _RestoreAccessScreenState extends ConsumerState<RestoreAccessScreen> {
  static const _bg = Color(0xFFF6F7F9);
  static const _blue = Color(0xFF3F4F86);

  final _emailCtrl = TextEditingController();
  bool _agreed = false;

  final Map<String, String?> _errors = {};

  final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool _isValidEmail(String s) => _emailRe.hasMatch(s.trim());

  bool _navigated = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _navigateOnce(VoidCallback go) {
    if (_navigated) return;
    _navigated = true;
    go();
  }

  void _setError(String key, String? msg) => _errors[key] = msg;

  void _clearField(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

  bool _validateAndShow() {
    _errors.clear();

    bool ok = true;
    String? firstError;

    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _setError('email', 'Введите e-mail');
      firstError ??= 'Введите e-mail';
      ok = false;
    } else if (!_isValidEmail(email)) {
      _setError('email', 'E-mail введен не корректно');
      firstError ??= 'E-mail введен не корректно';
      ok = false;
    }

    if (!_agreed) {
      _setError('agreement', 'Примите пользовательское соглашение');
      firstError ??= 'Примите пользовательское соглашение';
      ok = false;
    }

    setState(() {});

    if (firstError != null) {
      showAppMessageBar(context, firstError);
      return false;
    }
    return ok;
  }

  Future<void> _submit() async {
    // Сначала валидируем
    if (!_validateAndShow()) {
      // Если валидация не прошла, показываем ошибку и выходим
      return;
    }

    // Все поля в порядке — показываем капчу
    final ok = await showSlideCaptchaSheet(context);
    if (!ok) return;

    // Капча пройдена — выполняем восстановление доступа
    await ref
        .read(authControllerProvider.notifier)
        .restoreAccess(_emailCtrl.text.trim());
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

    // ✅ после успешного restoreAccess контроллер должен выставить pendingActivationEmail/isAccount=false
    ref.listen(authControllerProvider, (prev, next) {
      if (!context.mounted) return;
      if (prev?.pendingActivationEmail == null &&
          next.pendingActivationEmail != null) {
        _navigateOnce(() {
          Navigator.of(
            context,
          ).pushReplacementNamed('/activate', arguments: false);
        });
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Молитва мира',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              Image.asset(
                'assets/png/pray_hands.png',
                height: 84,
                width: 84,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              const Text(
                'Восстановление доступа',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              const Label('E-mail'),
              Input(
                controller: _emailCtrl,
                hint: '',
                error: _errors['email'],
                onChanged: (_) => _clearField('email'),
              ),

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

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
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
                      : const Text('Восстановить доступ'),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Если нет\nаккаунта, зарегистрируйтесь',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

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
                  onPressed: auth.isLoading
                      ? null
                      : () => Navigator.of(context).pushNamed('/register'),
                  child: const Text('Регистрация'),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementMini extends StatelessWidget {
  final bool checked;
  final bool isError;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenAgreement;

  const _AgreementMini({
    required this.checked,
    required this.isError,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenAgreement,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isError ? Colors.red : Colors.black26;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: const Color(0xFF3F4F86),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.25,
                  ),
                  children: [
                    const TextSpan(text: 'Принимаю '),
                    TextSpan(
                      text: 'Политику конфиденциальности',
                      style: const TextStyle(
                        color: Color(0xFF3F4F86),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                    ),
                    const TextSpan(text: ' и '),
                    TextSpan(
                      text: 'Пользовательское соглашение',
                      style: const TextStyle(
                        color: Color(0xFF3F4F86),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = onOpenAgreement,
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

const _privacyText =
    'Политика конфиденциальности\n\n(Текст будет добавлен позже)';
const _agreementText =
    'Пользовательское соглашение\n\n(Текст будет добавлен позже)';

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
