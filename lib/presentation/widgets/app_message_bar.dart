import 'package:flutter/material.dart';


void showAppMessageBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 2),
      Color brand = const Color(0xFFFF6A00)
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
        side: BorderSide(color: brand),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: brand,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      duration: duration,
    ),
  );
}
