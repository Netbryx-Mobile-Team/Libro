import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libro/features/auth/view_model/signup_view_model.dart';
import 'package:libro/shared/widgets/custom_snackbar.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  // Callback to execute after OTP is successfully verified
  final Future<void> Function() onVerified;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 🔹 AUTOMATICALLY SEND EMAIL OTP ONCE SCREEN IS BUILT
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendEmailOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // 🔹 CALLS THE VIEWMODEL TO SEND EMAIL OTP
  Future<void> _sendEmailOtp() async {
    try {
      await ref
          .read(signupViewModelProvider.notifier)
          .sendEmailOtp(widget.email, onCodeSent: () {
        if (!mounted) return;
        CustomSnackbar.show(
          context: context,
          message: 'Verification code sent to ${widget.email}',
        );
      });
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Error sending email: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // 🔹 CALLS THE VIEWMODEL TO VERIFY EMAIL OTP
  Future<void> _verifyEmailOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: 'Enter verification code',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      // 1. Verify with backend via ViewModel
      await ref.read(signupViewModelProvider.notifier).verifyEmailOtp(code);

      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Email verified!',
      );

      // 2. Call the completion callback (creates account in backend)
      await widget.onVerified();
      
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Verification failed: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the loading state
    final isLoading = ref.watch(signupViewModelProvider).isLoading;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Reset state when back is pressed
          ref.read(signupViewModelProvider.notifier).resetState();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Email Verification')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Enter the code sent to ${widget.email}'),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Verification Code'),
                maxLength: 6,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyEmailOtp,
                      child: const Text('Verify Email'),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _sendEmailOtp,
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}