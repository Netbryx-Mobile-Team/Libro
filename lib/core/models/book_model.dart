import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String sellerUid;
  final String ownerName;
  final String title;
  final String author;
  final String description;
  final String condition; // 'New', 'Used'
  final String type; // 'Fiction', 'Non-Fiction'
  final List<String> genres;
  final String contactPhone;
  final String address;
  final List<String> bookImagesBase64;
  final DateTime uploadDate;

  final String status; // 'active', 'sold', 'rented'

  // Optional fields
  final String? price;
  final String? exchangeBookTitle;
  final String? location; // <-- NEW FIELD

  BookModel({
    required this.id,
    required this.sellerUid,
    required this.ownerName,
    required this.title,
    required this.author,
    required this.description,
    required this.condition,
    required this.type,
    required this.genres,
    required this.contactPhone,
    required this.address,
    required this.bookImagesBase64,
    required this.uploadDate,
    required this.status,
    this.price,
    this.exchangeBookTitle,
    this.location, // NEW
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String documentId) {
    final timestamp = map['uploadDate'] as Timestamp?;
    final uploadDate = timestamp?.toDate() ?? DateTime.now();

    final genresList =
        (map['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];
    final imagesList =
        (map['bookImagesBase64'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    return BookModel(
      id: documentId,
      sellerUid: map['sellerUid'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? 'Unknown Owner',
      title: map['title'] as String? ?? 'Untitled Book',
      author: map['author'] as String? ?? 'Unknown Author',
      description: map['description'] as String? ?? 'No description provided.',
      condition: map['condition'] as String? ?? 'Used',
      type: map['type'] as String? ?? 'Fiction',
      genres: genresList,
      contactPhone: map['contactPhone'] as String? ?? 'N/A',
      address: map['address'] as String? ?? 'N/A',
      bookImagesBase64: imagesList,
      uploadDate: uploadDate,
      status: map['status'] as String? ?? 'active',
      price: map['price'] as String?,
      exchangeBookTitle: map['exchangeBookTitle'] as String?,
      location: map['location'] as String?, // <-- NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerUid': sellerUid,
      'ownerName': ownerName,
      'title': title,
      'author': author,
      'description': description,
      'condition': condition,
      'type': type,
      'genres': genres,
      'contactPhone': contactPhone,
      'address': address,
      'bookImagesBase64': bookImagesBase64,
      'uploadDate': FieldValue.serverTimestamp(),
      'status': status,
      'price': price,
      'exchangeBookTitle': exchangeBookTitle,
      'location': location, // <-- SAVE TO FIRESTORE
    };
  }
}
