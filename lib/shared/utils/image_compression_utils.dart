import 'dart:io';

class ImageUtils {
  static const int _maxSizeInBytes = 3 * 1024 * 1024; // 3 MB

  /// Checks if a file is within the allowed size limit
  static Future<bool> isFileSizeValid(File file) async {
    final int sizeInBytes = await file.length();
    return sizeInBytes <= _maxSizeInBytes;
  }

  /// Helper to get file size in MB string (for error messages)
  static Future<String> getFileSizeString(File file) async {
    final int sizeInBytes = await file.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);
    return "${sizeInMb.toStringAsFixed(2)} MB";
  }
}
