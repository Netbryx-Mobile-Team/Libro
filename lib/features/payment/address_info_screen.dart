import 'package:flutter/material.dart';
import 'package:libro/core/models/book_model.dart';

class CheckoutInfoScreen extends StatelessWidget {
  final BookModel book;
  final String fullName;
  final String address;
  final String cnic;
  final String contact;
  final double totalAmount;

  // Add this field
  final Future<void> Function()? onWorkingOnOrderPressed;

  const CheckoutInfoScreen({
    super.key,
    required this.book,
    required this.fullName,
    required this.address,
    required this.cnic,
    required this.contact,
    required this.totalAmount,
    this.onWorkingOnOrderPressed, // assign it here
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Information')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book: ${book.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Seller: ${book.ownerName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text('Full Name: $fullName', style: const TextStyle(fontSize: 16)),
            Text('Address: $address', style: const TextStyle(fontSize: 16)),
            Text('CNIC: $cnic', style: const TextStyle(fontSize: 16)),
            Text('Contact: $contact', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text('Total Amount: Rs.${totalAmount.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: onWorkingOnOrderPressed, // call the callback
                child: const Text('Mark as Working on Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
