// lib/features/auth/view/screens/signup_screen.dart

import 'package:libro/exports.dart';
import 'package:libro/features/auth/view/screens/login_screen.dart';

// This is now just a wrapper to open LoginScreen in 'Signup' mode
// Preserves file structure to prevent import errors in other files.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly return the consolidated LoginScreen with isSignup = true
    return const LoginScreen(initialIsSignup: true);
  }
}
