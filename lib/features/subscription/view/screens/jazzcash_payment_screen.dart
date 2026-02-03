import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:libro/features/subscription/view/screens/payment_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libro/features/notifications/view_model/notification_view_model.dart';

class JazzCashPaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String productName;

  const JazzCashPaymentScreen({
    super.key,
    required this.amount,
    required this.productName,
  });

  @override
  ConsumerState<JazzCashPaymentScreen> createState() =>
      _JazzCashPaymentScreenState();
}

class _JazzCashPaymentScreenState extends ConsumerState<JazzCashPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  bool isLoading = false;

  final String _merchantId = "MC336331";
  final String _password = "yv52ys7201";
  final String _integritySalt = "497351fbv4";
  final String _returnUrl = "https://www.google.com";

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      DateTime now = DateTime.now();
      String ppDateTime = DateFormat("yyyyMMddHHmmss").format(now);
      String ppExpiryDateTime = DateFormat(
        "yyyyMMddHHmmss",
      ).format(now.add(const Duration(hours: 1)));
      String ppTxnRefNo = "T${now.millisecondsSinceEpoch}";
      String ppBillReference = "bill${DateFormat('ddHHmmss').format(now)}";
      String ppAmount = widget.amount.toInt().toString();
      String ppMobileNumber = mobileController.text.trim();
      String ppCNIC = cnicController.text.trim();

      Map<String, String> params = {
        "pp_Amount": ppAmount,
        "pp_BankID": "TBANK",
        "pp_BillReference": ppBillReference,
        "pp_CNIC": ppCNIC,
        "pp_Description": "Payment",
        "pp_Language": "EN",
        "pp_MerchantID": _merchantId,
        "pp_MobileNumber": ppMobileNumber,
        "pp_Password": _password,
        "pp_ProductID": "RETL",
        "pp_ReturnURL": _returnUrl,
        "pp_TxnCurrency": "PKR",
        "pp_TxnDateTime": ppDateTime,
        "pp_TxnExpiryDateTime": ppExpiryDateTime,
        "pp_TxnRefNo": ppTxnRefNo,
        "pp_TxnType": "MWALLET",
        "pp_Version": "2.0",
      };

      var sortedParams = SplayTreeMap<String, String>.from(params);
      String rawString = _integritySalt;
      sortedParams.forEach((key, value) {
        if (value.isNotEmpty) rawString += "&$value";
      });

      var key = utf8.encode(_integritySalt);
      var bytes = utf8.encode(rawString);
      var hmacSha256 = Hmac(sha256, key);
      var digest = hmacSha256.convert(bytes);
      String secureHash = digest.toString().toUpperCase();

      params["pp_SecureHash"] = secureHash;

      final response = await http.post(
        Uri.parse(
          "https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction",
        ),
        body: params,
      );

      var body = jsonDecode(response.body);
      String responseCode = body['pp_ResponseCode'] ?? '999';
      String responseMessage = body['pp_ResponseMessage'] ?? 'Unknown';

      if (responseCode == '000' ||
          responseCode == '124' ||
          responseCode == '121') {
        _showSuccessDialog(
          "Success",
          "Check MPIN on $ppMobileNumber.\nRef: ${body['pp_TxnRefNo']}",
        );
      } else {
        _showErrorDialog("Failed", "$responseMessage ($responseCode)");
      }
    } catch (e) {
      _showErrorDialog("Error", "Connection Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleSuccess();
            },
            child: const Text(
              "I Have Paid",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (widget.productName.contains("Plan")) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'storeCredits': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      // FIX: Added ref.read() for notification
      await ref
          .read(notificationViewModelProvider)
          .notifySubscriptionPaid(
            userId: user.uid,
            planName: widget.productName,
            amount: widget.amount,
          );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JazzCash Payment"),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.network(
                "https://upload.wikimedia.org/wikipedia/commons/7/7b/JazzCash_logo.png",
                height: 80,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.payment, size: 80, color: Colors.red),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Text("Amount"),
                    Text(
                      "Rs. ${widget.amount}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: "Mobile (03...)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.length < 11 ? "Enter valid number" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: cnicController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: "CNIC (Last 6 Digits)",
                  border: OutlineInputBorder(),
                  helperText: "Sandbox Only",
                ),
                validator: (v) => v!.length < 6 ? "Enter last 6 digits" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Pay Now",
                          style: TextStyle(color: Colors.white),
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
