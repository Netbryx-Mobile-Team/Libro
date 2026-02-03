// lib/shared/utils/validation_utils.dart

class ValidationUtils {
  // Regex patterns (should be moved to shared/constants/regex_expressions.dart for cleaner code if many)
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _passwordRegex = RegExp(
    r'^.{6,}$',
  ); // Minimum 6 characters
  // CNIC format (e.g., XXXXX-XXXXXXX-X)
  static final RegExp _cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');

  // --- Core Validation Functions ---

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required.';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters.';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }
    // Assuming phone numbers will be validated/formatted by mask_text_input_formatter
    // For basic check:
    if (value.length < 11) {
      return 'Invalid phone number length.';
    }
    return null;
  }

  // --- Vendor Specific Validation ---

  String? validateCnic(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required for vendors.';
    }
    if (!_cnicRegex.hasMatch(value)) {
      return 'Invalid CNIC format (e.g., 12345-6789012-3).';
    }
    return null;
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}
