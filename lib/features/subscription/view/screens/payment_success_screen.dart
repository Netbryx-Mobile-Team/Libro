import 'package:libro/exports.dart';
import 'package:libro/features/vendor/view/screens/add_store_screen.dart'; // Adjust import path

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.kPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: const BoxDecoration(
                  color: whiteColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.teal,
                  size: 60.sp,
                ),
              ),
              gapH32,
              Text(
                "Payment Confirmed!",
                style: AppStyles.headingLarge.copyWith(color: whiteColor),
              ),
              gapH12,
              Text(
                "You have successfully subscribed to the Basic Plan.",
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              gapH40,
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Create Store Screen
                    // Replacement ensures back button goes to Home, not Payment Success
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStoreScreen(),
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
                    "Continue to Create Store",
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
      ),
    );
  }
}
