import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/upload/view_model/upload_view_model.dart';
import 'package:libro/shared/widgets/custom_snackbar.dart';

class BookUploadForm extends ConsumerStatefulWidget {
  final String uploadType; // 'Sell', 'Rent', 'Exchange'

  const BookUploadForm({super.key, required this.uploadType});

  @override
  ConsumerState<BookUploadForm> createState() => _BookUploadFormState();
}

class _BookUploadFormState extends ConsumerState<BookUploadForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController(); // NEW

  String _condition = 'New';
  String _category = 'Fiction';
  String _rentDuration = 'Week';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uploadState = ref.watch(uploadViewModelProvider);
    final notifier = ref.read(uploadViewModelProvider.notifier);
    final isRent = widget.uploadType == 'Rent';
    final isExchange = widget.uploadType == 'Exchange';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppDimens.kPadding,
        right: AppDimens.kPadding,
        top: AppDimens.kPadding,
        bottom: 120.h,
      ),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            GestureDetector(
              onTap: notifier.pickImages,
              child: Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primaryColor),
                ),
                child: uploadState.selectedImages.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 40, color: AppColors.primaryColor),
                          gapH8,
                          Text("Tap to add book images",
                              style: AppStyles.bodySmall),
                        ],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: uploadState.selectedImages.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              uploadState.selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            gapH24,

            // Title
            CustomTextField(
              controller: _titleController,
              hintText: "Book Title",
              radius: 30,
              validator: (v) => v!.isEmpty ? "Title required" : null,
            ),
            gapH16,

            // Description
            CustomTextField(
              controller: _descController,
              hintText: "Description",
              maxLines: 3,
              radius: 20,
              validator: (v) => v!.isEmpty ? "Description required" : null,
            ),
            gapH16,

            // Location Field ✅
            CustomTextField(
              controller: _locationController,
              hintText: "Book Location (Area, City)",
              radius: 30,
              validator: (v) => v!.isEmpty ? "Location required" : null,
            ),
            gapH16,

            // Price / Exchange
            if (isRent) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _priceController,
                      hintText: "Rent Amount",
                      keyboardType: TextInputType.number,
                      radius: 30,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  gapW12,
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _rentDuration,
                          isExpanded: true,
                          items: ['Day', 'Week', 'Month']
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text("/ $e")))
                              .toList(),
                          onChanged: (v) => setState(() => _rentDuration = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              CustomTextField(
                controller: _priceController,
                hintText:
                    isExchange ? "Book you want in exchange" : "Price (Rs.)",
                keyboardType:
                    isExchange ? TextInputType.text : TextInputType.number,
                radius: 30,
                validator: (v) => v!.isEmpty ? "Field required" : null,
              ),
            ],
            gapH16,

            // Condition + Category
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: InputDecoration(
                      labelText: "Condition",
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    items: ['New', 'Used']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                ),
                gapW12,
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: "Category",
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    items: [
                      'Fiction',
                      'Non-Fiction',
                      'Sci-Fi',
                      'Edu',
                      'Horror',
                      'Comedy',
                      'Thriller',
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ],
            ),
            gapH40,

            // Submit Button
            CustomButton(
              text: uploadState.isLoading
                  ? "Uploading..."
                  : "Upload for ${widget.uploadType}",
              isLoading: uploadState.isLoading,
              radius: 30,
              onPressed: () async {
  // IMAGE VALIDATION
  if (uploadState.selectedImages.isEmpty) {
    CustomSnackbar.show(
      context: context,
      message: "Please upload book image",
      backgroundColor: AppColors.errorRed,
    );
    return; // stop upload
  }

  if (_formKey.currentState!.validate()) {
    try {
      String collection = 'books';
      String priceValue = "";
      if (isRent) {
        priceValue = "${_priceController.text.trim()} / $_rentDuration";
      } else if (isExchange) {
        priceValue = "0";
      } else {
        priceValue = _priceController.text.trim();
      }

      // Convert images to base64
      List<String> bookImagesBase64 =
          await notifier.getBase64Images();
           // ✅ Use your ViewModel method

      await notifier.uploadBook(
        collection: collection,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: priceValue,
        condition: _condition,
        type: _category,
        transactionType: widget.uploadType,
        exchangePreference: isExchange ? _priceController.text.trim() : null,
        location: _locationController.text.trim(),
        storeId: 'YOUR_STORE_ID',
       bookImagesBase64: bookImagesBase64, // ✅ pass actual images
      );

      CustomSnackbar.show(
        context: context,
        message: "Book Uploaded Successfully!",
        backgroundColor: AppColors.successGreen,
      );

      // Clear fields
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _locationController.clear();

    } catch (e) {
      CustomSnackbar.show(
        context: context,
        message: e.toString(),
        backgroundColor: AppColors.errorRed,
      );
    }
  }
},

            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}
