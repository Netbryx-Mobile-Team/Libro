// lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String userType;
  final String? phone;
  final String? profileImageBase64;
  final String? cnic;
  final String? shopName;
  final String? shopAddress;
  final String? businessName;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    this.phone,
    this.profileImageBase64,
    this.cnic,
    this.shopName,
    this.shopAddress,
    this.businessName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'User',  // ← improved default
      userType: map['userType'] as String? ?? 'bookReader',
      phone: map['phone'] as String?,
      profileImageBase64: map['profileImageBase64'] as String?,
      cnic: map['cnic'] as String?,
      shopName: map['shopName'] as String?,
      shopAddress: map['shopAddress'] as String?,
      businessName: map['businessName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'phone': phone,
      'profileImageBase64': profileImageBase64,
      'cnic': cnic,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'businessName': businessName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Add this getter ───────────────────────────────────────────────────────
  String get firstName {
    if (name.trim().isEmpty) return 'User';
    
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first;
  }
}