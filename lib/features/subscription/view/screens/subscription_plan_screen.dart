import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ==========================================
// 1. STORE OWNER REGISTRATION FORM (NEW)
// ==========================================
class StoreOwnerRegistrationScreen extends StatefulWidget {
  const StoreOwnerRegistrationScreen({super.key});

  @override
  State<StoreOwnerRegistrationScreen> createState() => _StoreOwnerRegistrationScreenState();
}

class _StoreOwnerRegistrationScreenState extends State<StoreOwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveOwnerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      setState(() => _isSaving = false);
      return;
    }

    try {
      // Create document in store_owners collection
      await FirebaseFirestore.instance.collection('store_owners').doc(user.uid).set({
        'store_owner_id': user.uid, // Using UID as unique ID
        'name': _nameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _phoneController.text.trim(),
        'Subscription': false,
        'SubscriptionAmount': 1000,
        'SubscriptionFree': false,
        'SubscriptionTimePeriod': "year",
        'PromoCode': "LIBROFREE",
        'VoucherDeal': "",
        'payment': false,
        'payment_method': "",
      });

      if (mounted) {
        // Navigate to Subscription Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionPlanScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Owner Details"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Register your store profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "CNIC Number", border: OutlineInputBorder()),
                validator: (v) => v!.length < 13 ? "Enter valid CNIC" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Store/Home Address", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _isSaving ? null : _saveOwnerInfo,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Continue to Subscription", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SUBSCRIPTION PLAN SCREEN
// ==========================================
class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  bool _isProcessing = false;
  bool _isLoadingDetails = false;
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();

  double _currentAmount = 1000.0;
  String _currentTimePeriod = "year";
  String? _appliedVoucherCode;

  // JazzCash Credentials
  final String _merchantId = "MC123456";
  final String _password = "abc123";
  final String _integritySalt = "xyz987";
  final String _apiUrl = "https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction";
  final String _returnUrl = "https://your-return-url.com";

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscriptionDetails();
  }

  Future<void> _loadCurrentSubscriptionDetails() async {
    setState(() => _isLoadingDetails = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('store_owners').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentAmount = (doc.data()?['SubscriptionAmount'] ?? 1000).toDouble();
          _currentTimePeriod = doc.data()?['SubscriptionTimePeriod'] ?? 'year';
          _appliedVoucherCode = doc.data()?['PromoCode'];
        });
      }
    }
    setState(() => _isLoadingDetails = false);
  }

  // ... (Rest of your JazzCash Logic & Hash generation remains the same)

  String _generateSecureHash(Map<String, String> params) {
    var sortedParams = SplayTreeMap<String, String>.from(params);
    String rawString = _integritySalt;
    sortedParams.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        rawString += "&$value";
      }
    });

    var keyBytes = utf8.encode(_integritySalt);
    var dataBytes = utf8.encode(rawString);
    var hmacSha256 = Hmac(sha256, keyBytes);
    var digest = hmacSha256.convert(dataBytes);

    return digest.toString();
  }

  Future<void> _initiateJazzCashPayment(BuildContext context, double amount) async {
    final mobileNumber = _mobileController.text.trim();
    final cnicLast6 = _cnicController.text.trim();

    if (mobileNumber.isEmpty || mobileNumber.length != 11 || !mobileNumber.startsWith('03')) {
      _showDialog("Error", "Please enter a valid 11-digit JazzCash number.");
      return;
    }
    if (cnicLast6.isEmpty || cnicLast6.length != 6) {
      _showDialog("Error", "Please enter the last 6 digits of your CNIC.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      final ppDateTime = DateFormat("yyyyMMddHHmmss").format(now);
      final ppTxnRefNo = "T${now.millisecondsSinceEpoch}";
      final ppAmount = (amount * 100).toStringAsFixed(0);

      Map<String, String> params = {
        "pp_Version": "2.0",
        "pp_TxnType": "MWALLET",
        "pp_Language": "EN",
        "pp_MerchantID": _merchantId,
        "pp_Password": _password,
        "pp_TxnRefNo": ppTxnRefNo,
        "pp_Amount": ppAmount,
        "pp_TxnCurrency": "PKR",
        "pp_TxnDateTime": ppDateTime,
        "pp_BillReference": "LibroSub_${now.millisecondsSinceEpoch}",
        "pp_Description": "Libro Vendor Subscription",
        "pp_MobileNumber": mobileNumber,
        "pp_CNIC": cnicLast6,
        "pp_ReturnURL": _returnUrl,
      };

      params["pp_SecureHash"] = _generateSecureHash(params);

      final response = await http.post(Uri.parse(_apiUrl), body: params);
      final responseBody = json.decode(response.body);

      if (responseBody['pp_ResponseCode'] == '000') {
         // Update Firestore on success
         final user = FirebaseAuth.instance.currentUser;
         await FirebaseFirestore.instance.collection('store_owners').doc(user!.uid).update({
           'Subscription': true,
           'payment': true,
           'payment_method': 'JazzCash',
         });
        _showDialog("Success", "Subscription Activated!");
      } else {
        _showDialog("Payment Failed", responseBody['pp_ResponseMessage']);
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Choose Your Plan"),
        centerTitle: true,
      ),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Unlock Your Business Potential", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[800])),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text("BASIC VENDOR PLAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text("Rs. ${_currentAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                      Text(" / $_currentTimePeriod", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const VoucherSelectionScreen()));
                      if (result == true) _loadCurrentSubscriptionDetails();
                    },
                    icon: const Icon(Icons.local_offer, color: Colors.white),
                    label: const Text("View Vouchers", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "JazzCash Mobile Number",
                      hintStyle: const TextStyle(color: Colors.white60),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.phone, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _cnicController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "Last 6 digits of CNIC",
                      hintStyle: const TextStyle(color: Colors.white60),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.fingerprint, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _initiateJazzCashPayment(context, _currentAmount),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isProcessing ? const CircularProgressIndicator(color: Colors.teal) : Text("Subscribe & Create Store", style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. VOUCHER SELECTION SCREEN
// ==========================================
class VoucherSelectionScreen extends StatefulWidget {
  const VoucherSelectionScreen({super.key});

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> {
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _applyVoucher(String code, double newAmount, String timePeriod) async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // Update specific store owner document
      await FirebaseFirestore.instance.collection('store_owners').doc(user!.uid).update({
        'PromoCode': code,
        'SubscriptionAmount': newAmount,
        'SubscriptionTimePeriod': timePeriod,
        'VoucherDeal': "Active: $code", // Update deal value as requested
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voucher Applied Successfully!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Manual code handling and Voucher UI remains the same as your previous logic...
  void _handleManualCode() {
    String code = _manualCodeController.text.trim().toUpperCase();
    if (code == "ASKARI30") _applyVoucher(code, 700.0, "year");
    else if (code == "WELCOME") _applyVoucher(code, 850.0, "year");
    else if (code == "3MONTHSFREE") _applyVoucher(code, 0.0, "3 months");
    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Code")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Voucher"), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _manualCodeController, decoration: const InputDecoration(hintText: "Enter Code", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _handleManualCode, child: const Text("Apply"))
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVoucherCard("ASKARI30", "Askari Bank Special", 700.0, "year", Colors.teal),
                _buildVoucherCard("WELCOME", "New User Bonus", 850.0, "year", Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVoucherCard(String code, String title, double amt, String period, Color color) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text("Rs. $amt / $period"),
        trailing: ElevatedButton(onPressed: () => _applyVoucher(code, amt, period), child: const Text("Apply")),
      ),
    );
  }
}