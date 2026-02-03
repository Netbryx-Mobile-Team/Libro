import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/payment/address_form.dart';
import 'package:libro/features/vendor/view/screens/vendor_home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Assuming CheckoutForm is in the same file or properly imported
// If it's in another file, add: import 'path_to_checkout_form.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double subtotal = 1000.0;

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Choose Your Plan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimens.kPadding),
        child: Column(
          children: [
            Text(
              "Unlock Your Business Potential",
              textAlign: TextAlign.center,
              style: AppStyles.headingMedium.copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            gapH8,
            Text(
              "To maintain high quality, every new store on Libro requires a specialized hosting plan.",
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
            gapH16,
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      "BASIC VENDOR PLAN",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  gapH20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "Rs. 1000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        " / year",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  gapH24,
                  _buildFeatureRow("Create 1 Fully Functional Store"),
                  _buildFeatureRow("Upload Unlimited Books"),
                  _buildFeatureRow("Chat with Customers"),
                  _buildFeatureRow("Basic Analytics Dashboard"),
                  _buildFeatureRow("24/7 Support"),
                  gapH32,
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        // Check if user is logged in
                        if (FirebaseAuth.instance.currentUser == null) {
                          CustomSnackbar.show(
                            context: context,
                            message: "Please login first",
                            backgroundColor: Colors.red,
                          );
                          return;
                        }

                        // Go to CheckoutForm first (store owner info)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutForm(
                              book: BookModel(
                                // dummy book just to satisfy constructor - not used here
                                id: '',
                                title: 'Subscription Plan',
                                sellerUid: '',
                                ownerName: '',
                                author: '',
                                description: '',
                                condition: '',
                                type: '',
                                genres: [],
                                contactPhone: '',
                                address: '',
                                bookImagesBase64: [],
                                uploadDate: DateTime.now(),
                                status: '',
                              ),
                              totalAmount: subtotal,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Subscribe & Create Store",
                        style: TextStyle(
                          color: Colors.teal[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gapH20,
            Text(
              "Note: If you want to create multiple stores, you will need to purchase this plan for each store separately.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          gapW12,
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Payment Method Selection Screen (unchanged)
// ────────────────────────────────────────────────

class SubscriptionPaymentMethodScreen extends StatelessWidget {
  final double totalAmount;

  const SubscriptionPaymentMethodScreen({
    super.key,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('EasyPaisa'),
              subtitle: Text('Amount: Rs.${totalAmount.toStringAsFixed(0)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubscriptionPaymentInfoScreen(
                      method: 'EasyPaisa',
                      accountNumber: 'EASY123456',
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('JazzCash'),
              subtitle: Text('Amount: Rs.${totalAmount.toStringAsFixed(0)}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubscriptionPaymentInfoScreen(
                      method: 'JazzCash',
                      accountNumber: 'JAZZ654321',
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Payment Info / Send Screenshot Screen (unchanged)
// ────────────────────────────────────────────────

class SubscriptionPaymentInfoScreen extends StatelessWidget {
  final String method;
  final String accountNumber;
  final double totalAmount;

  const SubscriptionPaymentInfoScreen({
    super.key,
    required this.method,
    required this.accountNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay via $method')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Amount to pay: Rs.${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text('Send payment to account:', style: const TextStyle(fontSize: 16)),
            SelectableText(
              accountNumber,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              'After payment, send a screenshot to this WhatsApp number:',
              style: TextStyle(fontSize: 16),
            ),
            const SelectableText(
              '+92XXXXXXXXXX',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse('https://wa.me/+923063470775');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Send Payment Screenshot'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Go to Vendor Home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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