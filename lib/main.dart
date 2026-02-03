import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/auth/view/screens/splash_screen.dart';
import 'package:libro/features/auth/view/screens/login_screen.dart';
import 'package:libro/features/home/view/screens/bottom_navbar_screen.dart';
import 'package:libro/features/vendor/view/screens/vendor_bottom_nav_screen.dart';
import 'package:libro/shared/providers/firebase_providers.dart';

// --- Providers ---

final splashFinishedProvider = StateProvider<bool>((ref) => false);

/// 🔹 Real-time Stream: Listens to the user document.
final userRoleProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null; 
    final data = doc.data() as Map<String, dynamic>?;
    final rawUserType = data?['userType'] as String?;
    return (rawUserType ?? 'bookReader').toLowerCase().trim();
  });
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final isSplashFinished = ref.watch(splashFinishedProvider);

    if (!isSplashFinished) {
      Future.delayed(const Duration(seconds: 3), () {
        if (ref.read(splashFinishedProvider.notifier).mounted) {
          ref.read(splashFinishedProvider.notifier).state = true;
        }
      });
    }

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Libro App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          home: _buildHomeScreen(isSplashFinished, authState, ref),
        );
      },
    );
  }

  Widget _buildHomeScreen(
    bool isSplashFinished,
    AsyncValue<User?> authState,
    WidgetRef ref,
  ) {
    if (!isSplashFinished) {
      return const SplashScreen(key: ValueKey('splash_display'));
    }

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();

        // 🔹 THE FIX: Watch the role stream
        final roleState = ref.watch(userRoleProvider);

        // We check if the role data is actually present. 
        // If it's loading OR the data is null (doc doesn't exist yet), 
        // we stay on a clean loading screen.
        return roleState.when(
          data: (userType) {
            if (userType == null) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userType == 'vendor') {
              return const VendorBottomNavScreen();
            }
            return const BottomNavbarScreen(initialIndex: 0);
          },
          // 🔹 This stops the "Single Frame" flash of the Reader screen
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => const BottomNavbarScreen(initialIndex: 0),
        );
      },
      loading: () => const SplashScreen(key: ValueKey('splash_loading')),
      error: (err, stack) => const LoginScreen(),
    );
  }
}
