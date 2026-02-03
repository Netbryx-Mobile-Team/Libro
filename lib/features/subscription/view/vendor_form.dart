import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/core/models/book_model.dart';
import 'package:libro/features/payment/payment_method_screen.dart';
import 'package:libro/exports.dart'; // assuming this has AppColors, AppStyles, gap*, whiteColor, etc.

class CheckoutForm extends StatefulWidget {
  final BookModel book;
  final double totalAmount;

  const CheckoutForm({
    super.key,
    required this.book,
    required this.totalAmount,
  });

  @override
  State<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<CheckoutForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _cnicController;
  late TextEditingController _contactController;

  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _addressController = TextEditingController();
    _cnicController = TextEditingController();
    _contactController = TextEditingController();

    // Pre-fill existing data
    _loadExistingOwnerData();

    // Animation setup
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  Future<void> _loadExistingOwnerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('store_owners').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _fullNameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cnicController.text = data['cnic']?.toString() ?? '';
        _contactController.text = data['contact']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error loading owner data: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final uid = user.uid;

      final ownerData = {
        'name': _fullNameController.text.trim(),
        'address': _addressController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'contact': _contactController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email ?? '',
      };

      await FirebaseFirestore.instance
          .collection('store_owners')
          .doc(uid)
          .set(ownerData, SetOptions(merge: true));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentMethodScreen(
              book: widget.book,
              totalAmount: widget.totalAmount,
              fullName: _fullNameController.text.trim(),
              address: _addressController.text.trim(),
              cnic: _cnicController.text.trim(),
              contact: _contactController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cnicController.dispose();
    _contactController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.storefront_rounded, size: 48.w, color: AppColors.primaryColor),
                        gapH12,
                        Text(
                          'Store Owner Information',
                          style: AppStyles.headingMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        gapH8,
                        Text(
                          'This helps us verify and activate your store quickly',
                          textAlign: TextAlign.center,
                          style: AppStyles.bodySmall.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  gapH32,

                  // Form Fields
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  gapH20,

                  _buildTextField(
                    controller: _addressController,
                    label: 'Complete Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  gapH20,

                  _buildTextField(
                    controller: _cnicController,
                    label: 'CNIC Number',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Required';
                      if (t.length != 13 && t.length != 15) return '13 or 15 digits';
                      return null;
                    },
                  ),
                  gapH20,

                  _buildTextField(
                    controller: _contactController,
                    label: 'Contact Number',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),

                  gapH40,

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Proceed to Payment',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                    ),
                  ),

                  gapH40,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}