// lib/core/services/repair_old_books_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:libro/shared/constants/app_assets.dart';

class RepairOldBooksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fixOldBookImages() async {
    try {
      final String img1 = await _assetToBase64(AppAssets.bookImage1);
      final String img2 = await _assetToBase64(AppAssets.bookImage2);

      final List<String> pool = [img1, img2];

      final QuerySnapshot snapshot = await _firestore
          .collection('books_sell')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('bookImagesBase64') &&
            data['bookImagesBase64'] != null &&
            data['bookImagesBase64'].isNotEmpty) {
          continue;
        }

        await doc.reference.update({
          'bookImagesBase64': [pool[0], pool[1]],
        });

        print("Updated ${doc.id}");
      }

      print("All old books updated!");
    } catch (e) {
      print("Error repairing old books: $e");
      rethrow;
    }
  }

  Future<String> _assetToBase64(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      return "";
    }
  }
}
