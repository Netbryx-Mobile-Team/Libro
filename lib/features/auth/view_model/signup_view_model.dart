import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/features/auth/view_model/auth_view_model.dart';
import 'package:libro/shared/utils/validation_utils.dart';
import 'package:libro/shared/providers/app_providers.dart';

class SignupState {
  final bool isLoading;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String userType; // 'vendor' or 'bookReader'
  final String cnic;
  final String shopName;
  final String shopAddress;
  // 🔹 ADDED FIELDS FOR EMAIL OTP
  final String emailVerificationCode;
  final bool isEmailVerified;

  SignupState({
    this.isLoading = false,
    this.name = '',
    this.email = '',
    this.password = '',
    this.phone = '',
    this.userType = 'bookReader',
    this.cnic = '',
    this.shopName = '',
    this.shopAddress = '',
    // 🔹 INITIALIZE FIELDS
    this.emailVerificationCode = '',
    this.isEmailVerified = false,
  });

  SignupState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? userType,
    String? cnic,
    String? shopName,
    String? shopAddress,
    // 🔹 ADD FIELDS
    String? emailVerificationCode,
    bool? isEmailVerified,
  }) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      cnic: cnic ?? this.cnic,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      // 🔹 UPDATE FIELDS
      emailVerificationCode: emailVerificationCode ?? this.emailVerificationCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class SignupViewModel extends StateNotifier<SignupState> {
  final AuthRepository _authRepository;
  final AuthViewModel _authViewModel;
  final ValidationUtils _validator = ValidationUtils();

  SignupViewModel(this._authRepository, this._authViewModel)
      : super(SignupState()) {
    resetState();
  }

  // ---------------------------
  // Input Setters
  // ---------------------------
  void setName(String name) => state = state.copyWith(name: name.trim());
  void setEmail(String email) => state = state.copyWith(email: email.trim());
  void setPassword(String password) =>
      state = state.copyWith(password: password);
  void setPhone(String phone) => state = state.copyWith(phone: phone.trim());
  void setUserType(String type) => state = state.copyWith(userType: type);
  void setCnic(String cnic) => state = state.copyWith(cnic: cnic.trim());
  void setShopName(String shopName) =>
      state = state.copyWith(shopName: shopName.trim());
  void setShopAddress(String shopAddress) =>
      state = state.copyWith(shopAddress: shopAddress.trim());
  // 🔹 ADDED SETTER
  void setEmailVerificationCode(String code) =>
      state = state.copyWith(emailVerificationCode: code.trim());

  // ---------------------------
  // Validation
  // ---------------------------
  String? validateName(String? value) => _validator.validateName(value);
  String? validateEmail(String? value) => _validator.validateEmail(value);
  String? validatePassword(String? value) => _validator.validatePassword(value);
  String? validatePhone(String? value) => _validator.validatePhone(value);
  String? validateCnic(String? value) => _validator.validateCnic(value);
  String? validateShopName(String? value) =>
      _validator.validateRequired(value, 'Shop Name');
  String? validateShopAddress(String? value) =>
      _validator.validateRequired(value, 'Shop Address');

  // ---------------------------
  // Loading state
  // ---------------------------
  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  // ---------------------------
  // Verification Handling
  // ---------------------------
  
  // 🔹 UPDATED RESET METHOD
  void resetState() {
    state = SignupState(); // Resets to default (isLoading = false)
    // _verificationId = null; // ❌ REMOVE OLD PHONE DATA
    // _isPhoneVerified = false; // ❌ REMOVE OLD PHONE DATA
  }

  // 🔹 NEW METHOD: Send Email OTP (Backend Required)
  Future<void> sendEmailOtp(String email, {required Function() onCodeSent}) async {
    if (state.isLoading) return;
    setLoading(true);

    try {
      // TODO: Call your backend Cloud Function here to send the actual email
      // Example: await _authRepository.sendEmailCode(email);
      
      // Temporary: Simulate network delay for UI testing
      await Future.delayed(const Duration(seconds: 2));
      onCodeSent();
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // 🔹 NEW METHOD: Verify Email OTP (Backend Required)
  Future<void> verifyEmailOtp(String code) async {
    if (state.isLoading) return;
    setLoading(true);

    try {
      // TODO: Call your backend Cloud Function here to verify the code
      // Example: bool isValid = await _authRepository.verifyEmailCode(state.email, code);
      
      // Temporary: Simulate validation
      await Future.delayed(const Duration(seconds: 2));
      if (code == "123456") { // Dummy check
        state = state.copyWith(isEmailVerified: true);
      } else {
        throw "Invalid verification code";
      }
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // ---------------------------
  // Signup & Google Signup
  // ---------------------------
  Future<String?> signUp() async {
    _authViewModel.setLoading(true);
    try {
      final existingUsers = await _authRepository.firestoreService
          .getCollectionWhere(
        collection: 'users',
        field: 'email',
        isEqualTo: state.email,
      );

      if (existingUsers.isNotEmpty) {
        throw "This email is already used. Please login instead.";
      }

      final userData = await _authRepository.signUpWithEmailPassword(
        email: state.email,
        password: state.password,
        name: state.name,
        userType: state.userType,
        phone: state.phone,
        cnic: state.userType == 'vendor' ? state.cnic : null,
        shopName: state.userType == 'vendor' ? state.shopName : null,
        shopAddress: state.userType == 'vendor' ? state.shopAddress : null,
      );

      if (userData != null) {
        _authViewModel.setCurrentUser(userData);
        return userData.userType;
      }

      throw "Signup failed. Please try again.";
    } finally {
      _authViewModel.setLoading(false);
    }
  }

  Future<String?> signUpWithGoogle() async {
    _authViewModel.setLoading(true);
    try {
      final user = await _authRepository.signInWithGoogle(
        userType: state.userType,
        shopName: state.userType == 'vendor' ? state.shopName : null,
        shopAddress: state.userType == 'vendor' ? state.shopAddress : null,
        cnic: state.userType == 'vendor' ? state.cnic : null,
        phone: state.phone.isNotEmpty ? state.phone : null,
      );

      if (user == null) throw "Google sign-in cancelled or failed.";

      final userData = await _authRepository.getUserData(user.uid);
      if (userData == null) throw "User data not found in Firestore.";

      _authViewModel.setCurrentUser(userData);
      return userData.userType;
    } finally {
      _authViewModel.setLoading(false);
    }
  }
}

// ---------------------------
// Provider
// ---------------------------
final signupViewModelProvider =
    StateNotifierProvider<SignupViewModel, SignupState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authViewModel = ref.read(authViewModelProvider.notifier);
  return SignupViewModel(authRepository, authViewModel);
});