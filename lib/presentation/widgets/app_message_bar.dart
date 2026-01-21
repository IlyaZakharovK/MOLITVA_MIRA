import 'package:flutter/material.dart';

const _brandOrange = Color(0xFFFF6A00);

void showAppMessageBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 2),
    }) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 6,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _brandOrange),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: _brandOrange,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      duration: duration,
    ),
  );
}
