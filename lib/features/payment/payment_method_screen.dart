import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'payment_info_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  final BookModel book;
  final double totalAmount;

  // User & order-related info passed from CheckoutForm
  final String fullName;
  final String address;
  final String cnic;
  final String contact;

  const PaymentMethodScreen({
    super.key,
    required this.book,
    required this.totalAmount,
    required this.fullName,
    required this.address,
    required this.cnic,
    required this.contact,
  });

  /// Helper function to fetch store and navigate
  Future<void> _goToPaymentInfo(
      BuildContext context, String method, String accountNumber) async {
    try {
      // Fetch the store document from Firestore using book.sellerUid
      final storeSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(book.sellerUid)
          .get();

      if (!storeSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store not found')),
        );
        return;
      }

      final store = StoreModel.fromMap(storeSnapshot.data()!, storeSnapshot.id);

      // Navigate to PaymentInfoScreen with store
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentInfoScreen(
            method: method,
            accountNumber: accountNumber,
            book: book,
            totalAmount: totalAmount,
            fullName: fullName,
            address: address,
            cnic: cnic,
            contact: contact,
            store: store, // ✅ pass store here
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch store: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// EasyPaisa
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('EasyPaisa'),
              subtitle: Text('Amount: \$${totalAmount.toStringAsFixed(2)}'),
              onTap: () {
                _goToPaymentInfo(context, 'EasyPaisa', '03172442900');
              },
            ),

            /// JazzCash
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('JazzCash'),
              subtitle: Text('Amount: \$${totalAmount.toStringAsFixed(2)}'),
              onTap: () {
                _goToPaymentInfo(context, 'JazzCash', '03172442900');
              },
            ),
          ],
        ),
      ),
    );
  }
}
