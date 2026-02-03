import 'package:flutter_riverpod/legacy.dart';
import 'package:libro/core/models/user_model.dart';

// State now stores Firestore user info, not just Firebase User
class AuthState {
  final bool isLoading;
  final UserModel? currentUser;

  AuthState({this.isLoading = false, this.currentUser});

  AuthState copyWith({bool? isLoading, UserModel? currentUser}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(AuthState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setCurrentUser(UserModel? userModel) {
    state = state.copyWith(currentUser: userModel);
  }
}

// Provider
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
