import 'package:libro/exports.dart';

class BaseLayout extends StatelessWidget {
  final Widget child; // Screen ka main content
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Key? scaffoldKey;
  final bool resizeToAvoidBottomInset;

  const BaseLayout({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.drawer,
    this.appBar,
    this.scaffoldKey,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: whiteColor, // Fallback color
      body: Stack(
        children: [
          // --- 1. GLOBAL BACKGROUND IMAGE (Vector 1) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.vectorBackground1, // Aapki image
              height: 300
                  .h, // Height adjust karen (Header style ke liye 300.h theek he)
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // --- 2. SCREEN CONTENT ---
          SafeArea(bottom: false, child: child),
        ],
      ),
    );
  }
}
