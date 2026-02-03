// lib/features/auth/view/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../exports.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, Color(0xFF004D40)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Your Logo with Animation
            Image.asset(
              'assets/images/app_png/splash_book_img.png', 
              height: 120, // Removed .h temporarily to ensure it shows
              width: 120,  // Removed .w temporarily to ensure it shows
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(duration: 1000.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 20),
            
            // 2. Your Title with Animation
            Text(
              "Welcome to Libro",
              style: AppStyles.headingLarge.copyWith(
                color: Colors.white,
                fontSize: 32, // Fixed size to ensure visibility
              ),
            ).animate().fadeIn(delay: 300.ms),

            // NOTE: I removed the CircularProgressIndicator from here 
            // so the screen looks clean while you wait 3 seconds.
          ],
        ),
      ),
    );
  }
}