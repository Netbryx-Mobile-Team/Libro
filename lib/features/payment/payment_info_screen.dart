import 'package:flutter/material.dart'; 
import 'package:libro/core/models/book_model.dart';
import 'package:libro/core/models/store_model.dart';
import 'package:libro/features/home/view/screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentInfoScreen extends StatelessWidget {
  final String method;
  final String accountNumber;
  final BookModel book;
  final StoreModel store; // ✅ Add store
  final double totalAmount;

  // User & order info passed from previous screen
  final String fullName;
  final String address;
  final String cnic;
  final String contact;

  const PaymentInfoScreen({
    super.key,
    required this.method,
    required this.accountNumber,
    required this.book,
    required this.store, // ✅ Add store
    required this.totalAmount,
    required this.fullName,
    required this.address,
    required this.cnic,
    required this.contact,
  });

  Future<void> _placeOrder(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // Add order to Firestore AFTER payment confirmation
      await FirebaseFirestore.instance.collection('order').add({
        // 📘 Book info
        'bookId': book.id,
        'bookTitle': book.title,

        // 👤 Buyer info
        'userId': currentUser.uid,
        'fullName': fullName,
        'address': address,
        'cnic': cnic,
        'contact': contact,

        // 🏪 Vendor info
        'vendorId': store.uid,       // ✅ Use store.uid
        'vendorName': store.ownerName, // ✅ Use store.ownerName

        // 💰 Order info
        'totalAmount': totalAmount,
        'paymentMethod': method,
        'accountNumber': accountNumber,

        // 📦 Order state
        'orderPlaced': true,
        'payment': true,
        'orderStatus': 'Payment done', // initial status
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // Navigate to HomeScreen and remove all previous screens
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay via $method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Invoice Info
            Text('Book: ${book.title}', style: const TextStyle(fontSize: 18)),
            Text('Vendor: ${store.ownerName}', style: const TextStyle(fontSize: 18)), // ✅ use store.ownerName
            const SizedBox(height: 20),
            Text(
              'Send \$${totalAmount.toStringAsFixed(2)} to this account:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            SelectableText(
              accountNumber,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              'After payment, send a screenshot to this WhatsApp number:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 2),
            const SelectableText(
              '+92XXXXXXXXXX',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),

            // Button 1 → Send Payment Screenshot
            ElevatedButton(
              onPressed: () async {
                launchUrl(
                  Uri.parse("https://wa.me/+923172442900"),
                  mode: LaunchMode.externalApplication,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Send Payment Screenshot'),
            ),
            const SizedBox(height: 10),

            // Button 2 → Next → Place order & go to Home
            ElevatedButton(
              onPressed: () => _placeOrder(context), // ✅ fixed
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
