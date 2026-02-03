// lib/core/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String uid; // Vendor's UID
  final String shopName;
  final String shopDescription;
  final String shopAddress;
  final String ownerName;
  final String ownerCnic;
  final String contact;
  final List<String> shopImagesBase64; // Storing as Base64 strings in Firestore

  StoreModel({
    required this.uid,
    required this.shopName,
    required this.shopDescription,
    required this.shopAddress,
    required this.ownerName,
    required this.ownerCnic,
    required this.contact,
    required this.shopImagesBase64,
  });

  // Factory constructor to create StoreModel from Firestore Document
  factory StoreModel.fromMap(Map<String, dynamic> map, String documentId) {
    final imagesList =
        (map['shopImagesBase64'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return StoreModel(
      uid: documentId, // The store document ID is the Vendor's UID
      shopName: map['shopName'] as String? ?? 'Unnamed Store',
      shopDescription: map['shopDescription'] as String? ?? 'No description.',
      shopAddress: map['shopAddress'] as String? ?? 'No Address',
      ownerName: map['ownerName'] as String? ?? 'N/A',
      ownerCnic: map['ownerCnic'] as String? ?? 'N/A',
      contact: map['contact'] as String? ?? 'N/A',
      shopImagesBase64: imagesList,
    );
  }

  // Convert StoreModel to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'shopDescription': shopDescription,
      'shopAddress': shopAddress,
      'ownerName': ownerName,
      'ownerCnic': ownerCnic,
      'contact': contact,
      'shopImagesBase64': shopImagesBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
