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

final splashFinishedProvider = StateProvider<bool>((ref) => false);

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

    // Splash timer
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
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error or no document → treat as normal user (bookReader)
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const BottomNavbarScreen(initialIndex: 0);
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final rawUserType = data?['userType'] as String?;
            
            // Same default logic as in UserModel
            final userType = (rawUserType ?? 'bookReader').toLowerCase().trim();

            // Debug print (remove later if you want)
            // print('User: ${user.uid} | userType: $rawUserType → resolved: $userType');

            if (userType == 'vendor') {
              return const VendorBottomNavScreen();
            }

            // everything else including 'bookReader', null, empty, typos → user screen
            return const BottomNavbarScreen(initialIndex: 0);
          },
        );
      },
      loading: () => const SplashScreen(key: ValueKey('splash_loading')),
      error: (err, stack) {
        debugPrint('Auth error: $err');
        return const LoginScreen();
      },
    );
  }
}