import 'package:flutter/material.dart';

class BurgerButton extends StatelessWidget {
  final VoidCallback onPressed;

  /// Цвет линий (по умолчанию белый, как было)
  final Color color;

  /// Толщина линий (опционально)
  final double lineHeight;

  /// Скругление линий (опционально)
  final double lineRadius;

  const BurgerButton({
    super.key,
    required this.onPressed,
    this.color = Colors.white,
    this.lineHeight = 3,
    this.lineRadius = 2,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 26,
          height: 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Line(color: color, height: lineHeight, radius: lineRadius),
              _Line(color: color, height: lineHeight, radius: lineRadius),
              _Line(color: color, height: lineHeight, radius: lineRadius),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final Color color;
  final double height;
  final double radius;

  const _Line({
    required this.color,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
