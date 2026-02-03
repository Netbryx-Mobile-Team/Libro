import 'package:libro/exports.dart';

class BuyDummyScreen extends StatelessWidget {
  const BuyDummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 80, color: Colors.teal),
            gapH20,
            const Text(
              "Payment & Address Processing...",
              style: TextStyle(fontSize: 18),
            ),
            gapH20,
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                "Go Back",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
