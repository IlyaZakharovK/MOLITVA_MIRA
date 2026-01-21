import 'package:flutter/material.dart';
import 'package:slider_captcha/slider_captcha.dart';

Future<bool> showSlideCaptchaSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SlideCaptchaSheet(),
  );

  return result ?? false;
}

class _SlideCaptchaSheet extends StatefulWidget {
  const _SlideCaptchaSheet();

  @override
  State<_SlideCaptchaSheet> createState() => _SlideCaptchaSheetState();
}

class _SlideCaptchaSheetState extends State<_SlideCaptchaSheet> {
  final SliderController _controller = SliderController();

  static const List<String> _assets = [
    'assets/captcha/c1.png',
    'assets/captcha/c2.png',
    'assets/captcha/c3.png',
    'assets/captcha/c4.png',
    'assets/captcha/c5.png',
  ];

  int _idx = 0;

  void _nextImage() {
    if (_assets.length <= 1) return;
    setState(() {
      _idx = (_idx + 1) % _assets.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Защита от спама',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F4F86),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SliderCaptcha(
                      key: ValueKey('captcha_$_idx'),
                      controller: _controller,
                      colorCaptChar: Color(0xFF3F4F86),
                      colorBar: Color(0xFF3F4F85),
                      image: Image.asset(
                        _assets[_idx],
                        fit: BoxFit.cover,
                      ),
                      title: 'Передвиньте вправо',
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      onConfirm: (value) async {
                        if (value) {
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        } else {
                          _nextImage();
                          _controller.create();
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () {
                          _nextImage();
                          _controller.create();
                        },
                        child: const Text('Обновить изображение'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
