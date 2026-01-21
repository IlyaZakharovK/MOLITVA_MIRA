import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../common/slide_captcha_sheet.dart';
import '../widgets/app_message_bar.dart';
import '../widgets/input.dart';
import '../widgets/label.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _captchaVerified = false;

  final Map<String, String?> _errors = {};
  bool _navigated = false;

  final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  bool _isValidEmail(String s) => _emailRe.hasMatch(s.trim());

  @override
  void initState() {
    super.initState();

    // если pending уже был восстановлен из storage при старте — редиректим сразу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = ref.read(authControllerProvider);
      if (!mounted) return;

      if (st.pendingActivationEmail != null) {
        _navigateOnce(() {
          Navigator.of(context).pushReplacementNamed(
            '/activate',
            arguments: st.pendingActivationIsAccount ?? true,
          );
        });
        return;
      }

      if (st.session != null) {
        _navigateOnce(() {
          Navigator.of(context).pushReplacementNamed('/news');
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _navigateOnce(VoidCallback go) {
    if (_navigated) return;
    _navigated = true;
    go();
  }

  void _setError(String key, String? message) {
    _errors[key] = message;
  }

  void _clearField(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

  bool _validateAndShow() {
    _errors.clear();

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    String? firstError;

    if (email.isEmpty) {
      _setError('email', 'Введите e-mail');
      firstError ??= 'Введите e-mail';
    } else if (!_isValidEmail(email)) {
      _setError('email', 'E-mail введен не корректно');
      firstError ??= 'E-mail введен не корректно';
    }

    if (pass.trim().isEmpty) {
      _setError('password', 'Введите пароль');
      firstError ??= 'Введите пароль';
    }

    setState(() {});

    if (firstError != null) {
      showAppMessageBar(context, firstError);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateAndShow()) return;

    if (!_captchaVerified) {
      final ok = await showSlideCaptchaSheet(context);
      if (!ok) return;
      if (!mounted) return;
      setState(() => _captchaVerified = true);
    }

    ref.read(authControllerProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // ✅ ошибки из controller → в нижний бар
    ref.listen(
      authControllerProvider.select((s) => s.errorMessage),
          (prev, next) {
        if (!context.mounted) return;
        if (next != null && next.isNotEmpty && next != prev) {
          showAppMessageBar(context, next);
        }
      },
    );

    // ✅ навигация по состоянию
    ref.listen(authControllerProvider, (prev, next) {
      if (!context.mounted) return;

      if (prev?.pendingActivationEmail == null && next.pendingActivationEmail != null) {
        _navigateOnce(() {
          Navigator.of(context).pushReplacementNamed(
            '/activate',
            arguments: next.pendingActivationIsAccount ?? true,
          );
        });
        return;
      }

      if (prev?.session == null && next.session != null) {
        _navigateOnce(() {
          Navigator.of(context).pushReplacementNamed('/news');
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
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
                      'Войти в\nсвой аккаунт',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Label('Ваш e-mail'),
                    Input(
                      controller: _emailCtrl,
                      hint: '',
                      keyboardType: TextInputType.emailAddress,
                      error: _errors['email'],
                      onChanged: (_) => _clearField('email'),
                      onSubmitted: (_) => state.isLoading ? null : _submit(),
                    ),
                    const SizedBox(height: 12),

                    const Label('Ваш пароль'),
                    Input(
                      controller: _passCtrl,
                      hint: '',
                      obscureText: true,
                      error: _errors['password'],
                      onChanged: (_) => _clearField('password'),
                      onSubmitted: (_) => state.isLoading ? null : _submit(),
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed('/restore_access'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Забыли пароль?'),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                        onPressed: () {
                          if (!state.isLoading) _submit();
                        },
                        child: state.isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Войти'),
                      ),
                    ),

                    const SizedBox(height: 12),

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
                        onPressed: state.isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed('/register'),
                        child: const Text('Регистрация'),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
