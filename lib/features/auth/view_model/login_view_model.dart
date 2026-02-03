import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/repositories/auth_repository.dart';
import 'package:libro/features/auth/view_model/auth_view_model.dart';
import 'package:libro/shared/providers/app_providers.dart';
import 'package:libro/shared/utils/validation_utils.dart';

// 1. State Model
class LoginState {
  final String email;
  final String password;
  final bool isPasswordVisible;

  LoginState({
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }
}

// 2. State Notifier
class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final AuthViewModel _authViewModel;
  final ValidationUtils _validator = ValidationUtils();

  LoginViewModel(this._authRepository, this._authViewModel)
    : super(LoginState());

  // --- Input Handlers ---
  void setEmail(String email) => state = state.copyWith(email: email.trim());
  void setPassword(String password) =>
      state = state.copyWith(password: password);
  void togglePasswordVisibility() =>
      state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);

  // --- Validation ---
  String? validateEmail(String? value) => _validator.validateEmail(value);
  String? validatePassword(String? value) => _validator.validatePassword(value);

  // --- Login Logic ---
  Future<String?> login() async {
  _authViewModel.setLoading(true);
  try {
    final user = await _authRepository.signInWithEmailPassword(
      email: state.email,
      password: state.password,
    );

    if (user == null) {
      _authViewModel.setLoading(false);
      throw "User not found.";
    }

    // ✅ Fetch user data from Firestore
    final userData = await _authRepository.getUserData(user.uid);
    if (userData == null) {
      _authViewModel.setLoading(false);
      throw "User data not found in Firestore.";
    }

    _authViewModel.setCurrentUser(userData);

    _authViewModel.setLoading(false);

    // ✅ Return the role for navigation
    return userData.userType; // 'vendor' or 'bookReader'
  } on FirebaseAuthException catch (e) {
    _authViewModel.setLoading(false);
    throw e.message ?? "An unknown error occurred.";
  } catch (e) {
    _authViewModel.setLoading(false);
    throw "Login failed. Please try again.";
  }
}

  // --- Google Login Logic ---
  // THIS IS THE METHOD YOU WERE MISSING
  Future<String?> loginWithGoogle() async {
  _authViewModel.setLoading(true);
  try {
    final user = await _authRepository.signInWithGoogle(userType: '');
    if (user == null) {
      _authViewModel.setLoading(false);
      throw "Google sign-in cancelled or failed.";
    }

    // ✅ Fetch user data from Firestore
    final userData = await _authRepository.getUserData(user.uid);
    if (userData == null) {
      _authViewModel.setLoading(false);
      throw "User data not found in Firestore.";
    }

    _authViewModel.setCurrentUser(userData);
    _authViewModel.setLoading(false);

    // ✅ Return the role for navigation
    return userData.userType;
  } catch (e) {
    _authViewModel.setLoading(false);
    throw "Google login failed: ${e.toString()}";
  }
}

}

// 3. Provider
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      final authViewModel = ref.read(authViewModelProvider.notifier);
      return LoginViewModel(authRepository, authViewModel);
    });
