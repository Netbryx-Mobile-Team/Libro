// lib/shared/utils/navigation_utils.dart

import 'package:flutter/material.dart';

class NavigationUtils {
  // Use push to navigate to a new screen
  // Note: Removed 'static' so it works with 'navigation.push'
  Future<T?> push<T extends Object?>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen));
  }

  // Use pushReplacement to replace the current screen
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen,
  ) {
    return Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => screen));
  }

  // Use pushAndRemoveUntil to clear the stack and navigate to a new screen
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget screen,
  ) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (Route<dynamic> route) => false, // Clears all routes
    );
  }

  // Custom slide navigation with transition animation (for modern feel)
  Future<T?> slideNavigate<T extends Object?>(
    BuildContext context,
    Widget screen, {
    bool replace = false,
  }) {
    final pageRoute = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(pageRoute);
    }
    return Navigator.of(context).push(pageRoute);
  }

  // Pop the current route off the stack
  void pop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

// Quick Access Variable
// Ab aap poore app mein 'navigation.push(...)' use kar sakte hain
final navigation = NavigationUtils();
