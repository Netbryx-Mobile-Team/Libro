import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/core/services/firestore_service.dart';
import 'package:libro/features/auth/view_model/auth_view_model.dart';
import 'package:libro/shared/providers/app_providers.dart';
import 'package:libro/shared/utils/validation_utils.dart';

// ===============================
// 1️⃣ Signup State
// ===============================
class SignupState {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String userType; // 'vendor' or 'bookReader'

  // Vendor-specific fields
  final String cnic;
  final String shopName;
  final String shopAddress;

  SignupState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.phone = '',
    this.userType = 'bookReader',
    this.cnic = '',
    this.shopName = '',
    this.shopAddress = '',
  });

  SignupState copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? userType,
    String? cnic,
    String? shopName,
    String? shopAddress,
  }) {
    return SignupState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      cnic: cnic ?? this.cnic,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
    );
  }
}

// ===============================
// 2️⃣ Signup ViewModel
// ===============================
class SignupViewModel extends StateNotifier<SignupState> {
  final AuthRepository _authRepository;
  final AuthViewModel _authViewModel;
  final ValidationUtils _validator = ValidationUtils();

  SignupViewModel(this._authRepository, this._authViewModel)
      : super(SignupState());

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
  // Email/Password Signup
  // ---------------------------
  Future<String?> signUp() async {
  _authViewModel.setLoading(true);
  try {
    // 1️⃣ Check if email exists
    final existingUsers = await _authRepository.firestoreService
        .getCollectionWhere(
      collection: 'users',
      field: 'email',
      isEqualTo: state.email,
    );

    if (existingUsers.isNotEmpty) {
      _authViewModel.setLoading(false);
      throw "This email is already used. Please login instead.";
    }

    // 2️⃣ Create Firebase account + Firestore doc
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
      // ✅ Set current user with Firestore data immediately
      _authViewModel.setCurrentUser(userData);

      // ✅ Return userType for navigation
      _authViewModel.setLoading(false);
      return userData.userType;
    }

    throw "Signup failed. Please try again.";
  } catch (e) {
    _authViewModel.setLoading(false);
    throw e.toString();
  }
}


// ---------------------------
// Google Signup/Login
// ---------------------------
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

    // ✅ Fetch Firestore document immediately
    final userData = await _authRepository.getUserData(user.uid);
    if (userData == null)
      throw "User data not found in Firestore.";

    // ✅ Set current user with Firestore data
    _authViewModel.setCurrentUser(userData);

    // ✅ Return role for navigation
    _authViewModel.setLoading(false);
    return userData.userType;
  } catch (e) {
    _authViewModel.setLoading(false);
    throw e.toString();
  }
}
}
// ===============================
// 3️⃣ Provider
// ===============================
final signupViewModelProvider =
    StateNotifierProvider<SignupViewModel, SignupState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authViewModel = ref.read(authViewModelProvider.notifier);
  return SignupViewModel(authRepository, authViewModel);
});
