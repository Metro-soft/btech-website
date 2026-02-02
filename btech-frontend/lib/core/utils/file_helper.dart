import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FileHelper {
  /// Picks an image file and returns it as a Base64 encoded Data URI.
  /// Returns null if user cancels or error occurs.
  static Future<String?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.bytes != null) {
          String base64String = base64Encode(file.bytes!);
          String mimePrefix = 'data:image/${file.extension};base64,';
          return mimePrefix + base64String;
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }
}
