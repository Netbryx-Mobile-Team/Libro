// lib/core/services/storage_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  // --- Image Picking with Compression ---
  Future<List<File>> pickImages({int maxCount = 3}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 25, // Essential for Base64 to stay under 1MB Firestore limit
      maxWidth: 800, 
      maxHeight: 800, 
    );

    if (images.isNotEmpty) {
      final selected = images.length > maxCount ? images.sublist(0, maxCount) : images;
      return selected.map((xfile) => File(xfile.path)).toList();
    }
    return [];
  }
// ✅ ADD THIS BACK for your Chat Bubbles
  Uint8List dataFromBase64String(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint("Error decoding base64: $e");
      return Uint8List(0); // Returns empty list if data is corrupted
    }
  }
  // --- Base64 Encoding ---
  // Updated with try-catch to prevent PathNotFoundException from breaking the loop
  Future<List<String>> encodeFilesToBase64(List<File> files) async {
    final List<String> base64List = [];
    for (var file in files) {
      try {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          base64List.add(base64Encode(bytes));
        }
      } catch (e) {
        debugPrint("Error encoding file: $e");
        // Skip this specific file if it's missing or corrupted
      }
    }
    return base64List;
  }

  // --- Displaying Base64 ---
  Image imageFromBase64String(String base64String) {
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (e) {
      return Image.asset('assets/placeholder.png'); // Fallback if decoding fails
    }
  }
}

// Global Provider
final storageServiceProvider = Provider((ref) => StorageService());