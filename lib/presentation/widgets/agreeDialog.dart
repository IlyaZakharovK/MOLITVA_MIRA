import 'package:flutter/material.dart';

class AgreementRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;
  final bool showError;

  const AgreementRow({
    required this.value,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenTerms,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = showError ? Colors.red : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              side: const BorderSide(color: Colors.black26),
              activeColor: const Color(0xFF0A2A52),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'принимаю условия ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                InkWell(
                  onTap: onOpenPrivacy,
                  child: const Text(
                    'политики конфиденциальности',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F4F86),
                      decoration: TextDecoration.underline,
                      height: 1.2,
                    ),
                  ),
                ),
                const Text(
                  ' и ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                InkWell(
                  onTap: onOpenTerms,
                  child: const Text(
                    'пользовательского соглашения',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F4F86),
                      decoration: TextDecoration.underline,
                      height: 1.2,
                    ),
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
