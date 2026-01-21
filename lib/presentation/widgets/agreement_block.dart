import 'package:flutter/material.dart';

class AgreementBlock extends StatelessWidget {
  final bool isChecked;
  final bool isError;

  /// Вызывается при смене значения (клик по чекбоксу или по блоку)
  final ValueChanged<bool> onChanged;

  /// Открыть политику конфиденциальности
  final VoidCallback onOpenPrivacy;

  /// Открыть пользовательское соглашение
  final VoidCallback onOpenAgreement;

  const AgreementBlock({
    super.key,
    required this.isChecked,
    required this.isError,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenAgreement,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isError ? Colors.red : const Color(0x22000000);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Align(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: const Color(0xFF3F4F86),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Я принимаю '),

                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        style: TextStyle(fontSize: 11),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onOpenPrivacy,
                          child: const Text(
                            'Политику конфиденциальности',
                            style: TextStyle(
                              color: Color(0xFF3F4F86),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const TextSpan(text: ' и '),

                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        style: TextStyle(fontSize: 11),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onOpenAgreement,
                          child: const Text(
                            'Пользовательское соглашение',
                            style: TextStyle(
                              color: Color(0xFF3F4F86),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
