import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class ActivateEmailScreen extends ConsumerStatefulWidget {
  /// true  => appActivateAccount
  /// false => appRecoverAccountActivate
  final bool isAccountActivation;

  const ActivateEmailScreen({
    super.key,
    required this.isAccountActivation,
  });

  @override
  ConsumerState<ActivateEmailScreen> createState() => _ActivateEmailScreenState();
}

class _ActivateEmailScreenState extends ConsumerState<ActivateEmailScreen> {
  final _codeCtrl = TextEditingController();

  // как в login/register
  final Map<String, String?> _errors = {};
  bool _showBottomError = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _setError(String key, String? message) {
    _errors[key] = message;
  }

  bool _validate() {
    _errors.clear();
    _showBottomError = false;

    if (_codeCtrl.text.trim().isEmpty) {
      _setError('code', 'Введите код');
      _showBottomError = true;
    }

    setState(() {});
    return !_showBottomError;
  }

  void _submit() {
    if (!_validate()) return;

    final method = widget.isAccountActivation
        ? 'appActivateAccount'
        : 'appRecoverAccountActivate';

    ref.read(authControllerProvider.notifier).activateEmail(
      _codeCtrl.text.trim(),
      method: method,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final email = state.pendingActivationEmail ?? '';

    ref.listen(authControllerProvider, (prev, next) {
      // если активация завершилась (pending -> null), вернём на корень (логин)
      if (prev?.pendingActivationEmail != null &&
          next.pendingActivationEmail == null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
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

                    Text(
                      widget.isAccountActivation
                          ? 'Подтвердите\nemail'
                          : 'Подтвердите\nвосстановление доступа',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Код отправлен на: $email',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // серверная ошибка (как в логине)
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    const _Label('Код подтверждения *'),
                    _Input(
                      controller: _codeCtrl,
                      hint: '',
                      keyboardType: TextInputType.number,
                      error: _errors['code'],
                      onSubmitted: (_) => state.isLoading ? null : _submit(),
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
                        onPressed: state.isLoading ? null : _submit,
                        child: state.isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Подтвердить'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_showBottomError)
                      const Text(
                        'Введите код\nподтверждения',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
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
  final String hint;
  final TextInputType? keyboardType;
  final String? error;
  final ValueChanged<String>? onSubmitted;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
    required this.error,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isError = error != null;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isError ? Colors.red : Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isError ? Colors.red : Colors.black45),
        ),
      ),
    );
  }
}
