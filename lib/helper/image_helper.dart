import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/app_message_bar.dart';

const int kMaxUploadBytes = 10 * 1024 * 1024;

Future<Uint8List?> pickImageBytes(BuildContext context) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery);
  if (file == null) return null;

  final bytes = await file.readAsBytes();

  if (bytes.lengthInBytes > kMaxUploadBytes) {
    showAppMessageBar(
      context, 'Файл больше 10 МБ. Выберите изображение поменьше.',
      brand: Colors.redAccent
    );
    return null;
  }
  return bytes;
}