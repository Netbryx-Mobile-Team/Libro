import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libro/features/vendor/view_model/vendor_upload_view_model.dart';

class AddBookToStoreScreen extends ConsumerStatefulWidget {
  final String storeId;

  const AddBookToStoreScreen({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<AddBookToStoreScreen> createState() => _AddBookToStoreScreenState();
}

class _AddBookToStoreScreenState extends ConsumerState<AddBookToStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _genreController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  String _condition = 'New';
  File? _imagePreviewFile;
  XFile? _pickedXFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _genreController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController();
  }

  Future<void> _pickImage() async {
    final vm = ref.read(vendorUploadViewModelProvider);
    final XFile? picked = await vm.pickImage();

    if (picked != null && mounted) {
      setState(() {
        _pickedXFile = picked;
        _imagePreviewFile = File(picked.path); // for preview only
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedXFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a book cover image')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vm = ref.read(vendorUploadViewModelProvider);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await vm.uploadBook(
        storeId: widget.storeId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: _priceController.text.trim(),
        condition: _condition,
        type: _genreController.text.trim(),
        transactionType: 'Sale',
        exchangePreference: null,
        location: _locationController.text.trim(),
        pickedImage: _pickedXFile,
        sellerName: user.displayName ?? 'Unknown Seller',
        sellerUid: user.uid,
        context: context,
        collection: 'books_sell',
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
          (v) => v?.trim().isEmpty ?? true ? 'This field is required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Book'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade50,
                    ),
                    child: _imagePreviewFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _imagePreviewFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 60,
                                color: Colors.blue.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select book cover',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                _buildField('Book Title', _titleController),
                const SizedBox(height: 16),

                _buildField('Description', _descController),
                const SizedBox(height: 16),

                _buildField('Genre / Category', _genreController),
                const SizedBox(height: 16),

                _buildField(
                  'Price (PKR)',
                  _priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildField('Location (City/Area)', _locationController),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _condition,
                  decoration: InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'Like New', child: Text('Like New')),
                    DropdownMenuItem(value: 'Used', child: Text('Used')),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (v) => v != null ? setState(() => _condition = v) : null,
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(_isLoading ? 'Uploading...' : 'Add Book'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _genreController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}