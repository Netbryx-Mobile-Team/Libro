// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// class JazzCashService {
//   final String merchantId = "MC336331";
//   final String password = "yv52ys7201";
//   final String integritySalt = "497351fbv4";
//   final String returnUrl = "http://www.google.com";

//   Future<Map<String, dynamic>> pay({
//     required String mobile,
//     required String cnic,
//     required double amount,
//   }) async {
//     String dateTime = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
//     String expiry = DateFormat(
//       "yyyyMMddHHmmss",
//     ).format(DateTime.now().add(const Duration(hours: 1)));
//     String txnRef = "T$dateTime";

//     String ppAmount = (amount * 100).toInt().toString();

//     String superData =
//         integritySalt +
//         '&' +
//         ppAmount +
//         '&TBANK' +
//         '&bill$dateTime' +
//         '&cnic' +
//         '&Payment' +
//         '&EN' +
//         '&$merchantId' +
//         '&$mobile' +
//         '&$password' +
//         '&RETL' +
//         '&$returnUrl' +
//         '&PKR' +
//         '&$dateTime' +
//         '&$expiry' +
//         '&$txnRef' +
//         '&MWALLET' +
//         '&1.1';

//     var key = utf8.encode(integritySalt);
//     var bytes = utf8.encode(superData);
//     var hash = Hmac(sha256, key).convert(bytes).toString();

//     var response = await http.post(
//       Uri.parse(
//         "https://sandbox.jazzcash.com.pk/ApplicationAPI/API/Payment/DoTransaction",
//       ),
//       body: {
//         "pp_Version": "1.1",
//         "pp_TxnType": "MWALLET",
//         "pp_Language": "EN",
//         "pp_MerchantID": merchantId,
//         "pp_Password": password,
//         "pp_TxnRefNo": txnRef,
//         "pp_Amount": ppAmount,
//         "pp_TxnCurrency": "PKR",
//         "pp_TxnDateTime": dateTime,
//         "pp_BillReference": "bill$dateTime",
//         "pp_Description": "Payment",
//         "pp_TxnExpiryDateTime": expiry,
//         "pp_ReturnURL": returnUrl,
//         "pp_SecureHash": hash,
//         "pp_MobileNumber": mobile,
//         "pp_CNIC": cnic,
//         "pp_ProductID": "RETL",
//         "pp_BankID": "TBANK",
//       },
//     );

//     return jsonDecode(response.body);
//   }
// }
