// lib/features/orders/view/screens/orders_screen.dart  (or place wherever fits your structure)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:libro/exports.dart';                    // assuming this has AppStyles, gapH*, whiteColor, etc.
import 'package:libro/core/models/book_model.dart';     // BookModel
import 'package:libro/features/payment/address_info_screen.dart'; // CheckoutInfoScreen

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late final Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _ordersStream = FirebaseFirestore.instance
        .collection('order')
        .where('vendorId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimens.kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Orders", style: AppStyles.headingSmall),
            gapH12,

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders yet."));
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => gapH12,
                    itemBuilder: (context, index) {
                      final orderData = orders[index].data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          final book = BookModel(
                            id: orderData['bookId'] ?? '',
                            title: orderData['bookTitle'] ?? 'Unknown',
                            sellerUid: orderData['sellerUid'] ?? '', // ← note: you're still using sellerUid here
                            ownerName: orderData['ownerName'] ?? '',
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
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutInfoScreen(
                                book: book,
                                fullName: orderData['fullName'] ?? '',
                                address: orderData['address'] ?? '',
                                cnic: orderData['cnic'] ?? '',
                                contact: orderData['contact'] ?? '',
                                totalAmount: (orderData['totalAmount'] ?? 0).toDouble(),
                                onWorkingOnOrderPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('order')
                                      .doc(orders[index].id)
                                      .update({'orderStatus': 'working'});
                                  CustomSnackbar.show(
                                    context: context,
                                    message: "Order status updated to Working on Order",
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderData['bookTitle'] ?? 'Unknown',
                                    style: AppStyles.bodyMedium,
                                  ),
                                  Text(
                                    orderData['fullName'] ?? '',
                                    style: AppStyles.bodySmall,
                                  ),
                                ],
                              ),
                              Text(
                                orderData['orderStatus'] ?? 'Placed',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}