// lib/features/vendor/view/screens/add_store_screen.dart

import 'package:libro/core/models/store_model.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/upload/view/widgets/upload_image_picker.dart';
import 'package:libro/features/upload/view_model/upload_view_model.dart';
import 'package:libro/shared/providers/app_providers.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  const AddStoreScreen({super.key});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _shopNameController = TextEditingController();
  final _descController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _descController.dispose();
    _ownerNameController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitStore() async {
    if (!_formKey.currentState!.validate()) return;

    final uploadState = ref.read(uploadViewModelProvider);
    if (uploadState.selectedImages.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please add shop images",
        backgroundColor: AppColors.errorRed,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) throw "User session expired";

      // 1. Encode Images
      final base64Images = await ref
          .read(uploadViewModelProvider.notifier)
          .getBase64Images();

      // 2. Create Model
      final store = StoreModel(
        uid: user.uid,
        shopName: _shopNameController.text.trim(),
        shopDescription: _descController.text.trim(),
        shopAddress: _addressController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerCnic: _cnicController.text.trim(),
        contact: _phoneController.text.trim(),
        shopImagesBase64: base64Images,
      );

      // 3. Save to Firestore
      final storeRepo = ref.read(storeRepositoryProvider);
      await storeRepo.createStore(store);

      CustomSnackbar.show(
        context: context,
        message: "Store Created Successfully!",
        backgroundColor: AppColors.successGreen,
      );
      Navigator.pop(context); // Go back to Vendor Home
    } catch (e) {
      CustomSnackbar.show(
        context: context,
        message: "Error: $e",
        backgroundColor: AppColors.errorRed,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using the UploadViewModel purely for Image Picking logic
    final uploadState = ref.watch(uploadViewModelProvider);
    final uploadNotifier = ref.read(uploadViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Your Store"), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimens.kPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              UploadImagePicker(
                selectedImages: uploadState.selectedImages,
                onPickImages: uploadNotifier.pickImages,
                onRemoveImage: uploadNotifier.removeImage,
              ),
              gapH24,

              CustomTextField(
                controller: _shopNameController,
                hintText: "Shop Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              gapH16,
              CustomTextField(
                controller: _descController,
                hintText: "Shop Description",
                maxLines: 3,
              ),
              gapH16,
              CustomTextField(
                controller: _ownerNameController,
                hintText: "Owner's Name",
              ),
              gapH16,
              CustomTextField(
                controller: _cnicController,
                hintText: "Owner's CNIC (e.g 42101...)",
                keyboardType: TextInputType.number,
              ),
              gapH16,
              CustomTextField(
                controller: _addressController,
                hintText: "Shop Address",
              ),
              gapH16,
              CustomTextField(
                controller: _phoneController,
                hintText: "Contact Number",
                keyboardType: TextInputType.phone,
              ),

              gapH40,
              CustomButton(
                text: "Create Store",
                isLoading: _isSubmitting || uploadState.isLoading,
                onPressed: _submitStore,
              ),

              // --- CHANGE THIS VALUE TO INCREASE BOTTOM SPACE ---
              SizedBox(height: 100), // Increased from 10 to 100
            ],
          ),
        ),
      ),
    );
  }
}
