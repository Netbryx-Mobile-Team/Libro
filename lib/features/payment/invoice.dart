import 'package:flutter/material.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/features/payment/address_form.dart';
import 'payment_method_screen.dart';


class InvoiceScreen extends StatelessWidget {
  final BookModel book;

  const InvoiceScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final rawPrice = book.price?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
    final double price = double.tryParse(rawPrice) ?? 0.0;
    final double deliveryCharge = price * 0.05; // 5%
    final double appCharge = price * 0.01;      // 1%
    final double total = price + deliveryCharge + appCharge;

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book: ${book.title}', style: const TextStyle(fontSize: 18)),
            Text('Seller: ${book.ownerName}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Price: Rs.${price.toStringAsFixed(2)}'),
            Text('Delivery (5%): Rs.${deliveryCharge.toStringAsFixed(2)}'),
            Text('App Charge (1%): Rs.${appCharge.toStringAsFixed(2)}'),
            const Divider(height: 30, thickness: 2),
            Text('Total: Rs.${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Center(
              child: ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutForm(
          book: book, // Pass the whole book
          totalAmount: total, // Pass calculated total
        ),
      ),
    );
  },
  child: const Text('Next'),
),

            ),
          ],
        ),
      ),
    );
  }
}
