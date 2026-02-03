// lib/core/services/dummy_data_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:libro/shared/constants/app_assets.dart';

class DummyDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _rnd = Random();

  Future<void> uploadDummyBooks() async {
    final String img1 = await _assetToBase64(AppAssets.bookImage1);
    final String img2 = await _assetToBase64(AppAssets.bookImage2);
    final String placeholder = await _assetToBase64(AppAssets.placeholderImage);

    final List<String> imagesPool = [
      img1,
      img2,
    ].where((e) => e.isNotEmpty).toList();
    if (imagesPool.isEmpty && placeholder.isNotEmpty) {
      imagesPool.add(placeholder);
    }

    final List<Map<String, dynamic>> dummyBooks = [
      {
        'title': 'The Alchemist',
        'price': '1200',
        'condition': 'New',
        'type': 'Fiction',
        'description': 'A magical story about following your dreams.',
        'genres': ['Adventure', 'Philosophy'],
      },
      {
        'title': 'Rich Dad Poor Dad',
        'price': '1500',
        'condition': 'Used',
        'type': 'Non-Fiction',
        'description': 'Financial education and wealth building.',
        'genres': ['Education', 'Business'],
      },
      {
        'title': 'Harry Potter',
        'price': '2000',
        'condition': 'Used',
        'type': 'Fiction',
        'description': 'The boy who lived. Magical fantasy.',
        'genres': ['Fantasy', 'Adventure'],
      },
      {
        'title': 'Atomic Habits',
        'price': '1800',
        'condition': 'New',
        'type': 'Non-Fiction',
        'description': 'Tiny changes, remarkable results.',
        'genres': ['Self-help'],
      },
      {
        'title': 'Calculus Early Transcendentals',
        'price': '800',
        'condition': 'Used',
        'type': 'Education',
        'description': 'University level calculus book.',
        'genres': ['Education', 'Math'],
      },
    ];

    for (var book in dummyBooks) {
      final int chosenCount = imagesPool.length == 1
          ? 1
          : (_rnd.nextBool() ? 1 : 2);
      final List<String> chosen = List.generate(
        chosenCount,
        (_) => imagesPool[_rnd.nextInt(imagesPool.length)],
      );
      await _firestore.collection('books_sell').add({
        'sellerUid': 'DUMMY_ADMIN',
        'title': book['title'],
        'description': book['description'],
        'condition': book['condition'],
        'type': book['type'],
        'genres': book['genres'],
        'contactPhone': '03001234567',
        'address': 'Karachi, Pakistan',
        'bookImagesBase64': chosen,
        'uploadDate': FieldValue.serverTimestamp(),
        'price': book['price'],
        'exchangeBookTitle': null,
      });
    }
  }

  Future<String> _assetToBase64(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      return "";
    }
  }
}
