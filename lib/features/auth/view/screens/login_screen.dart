import 'package:flutter_animate/flutter_animate.dart';
import 'package:libro/exports.dart';
import 'package:libro/features/auth/view/screens/otp.dart';
import 'package:libro/features/auth/view_model/auth_view_model.dart';
import 'package:libro/features/auth/view_model/login_view_model.dart';
import 'package:libro/features/auth/view_model/signup_view_model.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsSignup;
  const LoginScreen({super.key, this.initialIsSignup = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isSignup;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Formatters
  final phoneFormatter = MaskTextInputFormatter(mask: '#### #######');
  final cnicFormatter = MaskTextInputFormatter(mask: '#####-#######-#');

  // Controllers
  final _cnicController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  // Consistent Height for smaller fields
  final double _fieldHeight = 38.0;
  final double _gapSmall = 8.0;

  @override
  void initState() {
    super.initState();
    _isSignup = widget.initialIsSignup;
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  void _toggleTab(bool isSignup) {
    setState(() {
      _isSignup = isSignup;
    });
  }

  // --- NEW: Clear Vendor Fields when switching to Reader ---
  void _handleUserTypeChange(String newType, SignupViewModel notifier) {
    // Agar Reader select kiya, to Vendor ka data clear kardo
    if (newType == 'reader') {
      _shopNameController.clear();
      _shopAddressController.clear();
      _cnicController.clear();

      // Update Notifier state immediately
      notifier.setShopName('');
      notifier.setShopAddress('');
      notifier.setCnic('');
    }
    // Update the type
    notifier.setUserType(newType);
  }

  @override
  Widget build(BuildContext context) {
    final authLoading = ref.watch(authViewModelProvider).isLoading;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: whiteColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // --- TOP TEAL BACKGROUND (75% height) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.83,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(100.r),
                  ),
                  child: Image.asset(
                    AppAssets.loginbg,
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),

              // --- MAIN CONTENT ---
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 15.h),

                      // HEADER TEXT
                      AnimatedSwitcher(
                        duration: 300.ms,
                        child: Column(
                          key: ValueKey(_isSignup),
                          children: [
                            Text(
                              _isSignup ? "Welcome to Libro" : "Welcome Back",
                              style: AppStyles.headingLarge.copyWith(
                                color: whiteColor,
                                fontSize: 24.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _isSignup
                                  ? "Create your account"
                                  : "Login to continue",
                              style: AppStyles.bodyMedium.copyWith(
                                color: whiteColor.withOpacity(0.9),
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10.h),

                      Expanded(
                        child: Column(
                          children: [
                            // TAB BAR
                            _buildAuthTabBar(),

                            SizedBox(height: 10.h),

                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: 300.ms,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      child: _isSignup
                                          ? _buildSignupForm(authLoading)
                                          : _buildLoginForm(authLoading),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Social Login Area
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: _buildSocialLoginSection(authLoading),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SMALLER COMPACT TAB BAR ---
  Widget _buildAuthTabBar() {
    return Container(
      height: 36.h,
      width: 250.w,
      decoration: BoxDecoration(
        color: whiteColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: whiteColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildTabItem(
            label: "Login",
            isActive: !_isSignup,
            onTap: () => _toggleTab(false),
          ),
          _buildTabItem(
            label: "Sign Up",
            isActive: _isSignup,
            onTap: () => _toggleTab(true),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // Improved Touch Response
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? whiteColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Center(
            child: Text(
              label,
              style: AppStyles.bodyLarge.copyWith(
                color: isActive ? const Color(0xFF004D40) : whiteColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIN FORM ---
  Widget _buildLoginForm(bool authLoading) {
    final loginNotifier = ref.read(loginViewModelProvider.notifier);
    final loginState = ref.watch(loginViewModelProvider);

    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          SizedBox(height: 15.h),
          _buildWhiteFieldWrapper(
            child: CustomTextField(
              hintText: "Email",
              keyboardType: TextInputType.emailAddress,
              radius: 30,
              height: _fieldHeight,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primaryColor,
                size: 18,
              ),
              onChanged: (email) => loginNotifier.setEmail(email),
              validator: loginNotifier.validateEmail,
            ),
          ),
          SizedBox(height: _gapSmall),
          _buildWhiteFieldWrapper(
            child: CustomTextField(
              hintText: "Password",
              obscureText: !loginState.isPasswordVisible,
              radius: 30,
              height: _fieldHeight,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primaryColor,
                size: 18,
              ),
              onChanged: (password) => loginNotifier.setPassword(password),
              validator: loginNotifier.validatePassword,
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                onPressed: loginNotifier.togglePasswordVisibility,
                icon: Icon(
                  loginState.isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
  final notifier = ref.read(loginViewModelProvider.notifier);

  try {
    await notifier.forgotPassword();

    if (mounted) {
      CustomSnackbar.show(
        context: context,
        message: "Password reset email sent. Check inbox.",
      );
    }
  } catch (e) {
    CustomSnackbar.show(
      context: context,
      message: e.toString(),
      backgroundColor: Colors.red,
    );
  }
},

              child: Text(
                "Forgot password?",
                style: AppStyles.bodySmall.copyWith(
                  color: whiteColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
          CustomButton(
            text: authLoading ? "Logging In..." : "Login",
            isLoading: authLoading,
            radius: 30,
            height: 40,
            backgroundColor: const Color(0xFF00332C),
            onPressed: () => _handleLogin(loginNotifier),
          ),
        ],
      ),
    );
  }

  // --- SIGNUP FORM ---
  Widget _buildSignupForm(bool authLoading) {
    final signupNotifier = ref.read(signupViewModelProvider.notifier);
    final signupState = ref.watch(signupViewModelProvider);

    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          // RADIO BUTTON SELECTOR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRadioOption(
                label: "Reader",
                value: "reader",
                groupValue: signupState.userType,
                onChanged: (val) => _handleUserTypeChange(val!, signupNotifier),
              ),
              SizedBox(width: 30.w), // Increased spacing for easier tapping
              _buildRadioOption(
                label: "Vendor",
                value: "vendor",
                groupValue: signupState.userType,
                onChanged: (val) => _handleUserTypeChange(val!, signupNotifier),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // COMPACT FIELDS
          _buildWhiteFieldWrapper(
            child: CustomTextField(
              hintText: "Full Name",
              radius: 30,
              height: _fieldHeight,
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.primaryColor,
                size: 18,
              ),
              onChanged: signupNotifier.setName,
              validator: signupNotifier.validateName,
            ),
          ),
          SizedBox(height: _gapSmall),
          _buildWhiteFieldWrapper(
            child: CustomTextField(
              hintText: "Email",
              keyboardType: TextInputType.emailAddress,
              radius: 30,
              height: _fieldHeight,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primaryColor,
                size: 18,
              ),
              onChanged: signupNotifier.setEmail,
              validator: signupNotifier.validateEmail,
            ),
          ),
          SizedBox(height: _gapSmall),
          _buildWhiteFieldWrapper(
            child: CustomTextField(
              hintText: "Password",
              obscureText: true,
              radius: 30,
              height: _fieldHeight,
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primaryColor,
                size: 18,
              ),
              onChanged: signupNotifier.setPassword,
              validator: signupNotifier.validatePassword,
            ),
          ),
          // PHONE FIELD (Only for Reader)
if (signupState.userType != 'vendor') ...[
  SizedBox(height: _gapSmall),
  _buildWhiteFieldWrapper(
    child: CustomTextField(
      hintText: "Phone #",
      keyboardType: TextInputType.phone,
      radius: 30,
      height: _fieldHeight,
      prefixIcon: const Icon(
        Icons.phone_outlined,
        color: AppColors.primaryColor,
        size: 18,
      ),
      inputFormatters: [phoneFormatter],
      onChanged: signupNotifier.setPhone,
      validator: signupNotifier.validatePhone,
    ),
  ),
],

          // VENDOR COMPACT FIELDS
          if (signupState.userType == 'vendor') ...[
            SizedBox(height: _gapSmall),
            _buildWhiteFieldWrapper(
              child: CustomTextField(
                controller: _shopNameController,
                hintText: "Shop Name",
                radius: 30,
                height: _fieldHeight,
                prefixIcon: const Icon(
                  Icons.store_outlined,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                onChanged: signupNotifier.setShopName,
                validator: signupNotifier.validateShopName,
              ),
            ).animate().fadeIn(),
           ],

          SizedBox(height: 15.h),

          CustomButton(
            text: authLoading ? "Creating..." : "Sign Up",
            isLoading: authLoading,
            radius: 30,
            height: 40,
            backgroundColor: const Color(0xFF00332C),
            onPressed: () => _handleSignup(signupNotifier),
          ),
        ],
      ),
    );
  }

  // --- Helper for Radio Buttons (Optimized for Touch) ---
  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque, // Ensures the whole area is clickable
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? whiteColor : whiteColor.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Container(
                height: 10.w,
                width: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? whiteColor : Colors.transparent,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                color: isSelected ? whiteColor : whiteColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteFieldWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: child,
    );
  }

  // --- LOGIC HANDLERS ---
  Future<void> _handleLogin(LoginViewModel notifier) async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        await notifier.login();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        CustomSnackbar.show(
          context: context,
          message: e.toString(),
          backgroundColor: Colors.red,
        );
      }
    }
  }

Future<void> _handleSignup(SignupViewModel notifier) async {
  if (!_signupFormKey.currentState!.validate()) {
    CustomSnackbar.show(
      context: context,
      message: "Please check all fields",
      backgroundColor: Colors.red,
    );
    return;
  }

  try {
    final state = ref.read(signupViewModelProvider);

    // 🔹 VENDOR FLOW: Must verify email first
    if (state.userType == "vendor") {
      // 🔹 Push the Email Verification Screen.
      // 🔹 It will call sendEmailOtp() in its initState.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: state.email, // 🔹 Pass the email here
            onVerified: () async {
              // 🔹 Complete signup after Email verified
              await notifier.signUp();

              if (!mounted) return;
              CustomSnackbar.show(
                context: context,
                message: "Account Created! Switching to Login...",
              );
              _toggleTab(false); // Switch to login tab
            },
          ),
        ),
      );
      return; // Exit after handling vendor
    }

    // ✅ Reader → Normal signup without verification
    await notifier.signUp();

    if (!mounted) return;
    CustomSnackbar.show(
      context: context,
      message: "Account Created! Switching to Login...",
    );
    _toggleTab(false);
  } catch (e) {
    if (!mounted) return;
    CustomSnackbar.show(
      context: context,
      message: e.toString(),
      backgroundColor: Colors.red,
    );
  }
}

  Future<void> _handleGoogleAuth(dynamic signupViewModelProvider) async {
    try {
      if (_isSignup) {
        await ref.read(signupViewModelProvider.notifier).signUpWithGoogle();
      } else {
        await ref.read(loginViewModelProvider.notifier).loginWithGoogle();
      }
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      CustomSnackbar.show(
        context: context,
        message: e.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildSocialLoginSection(bool isLoading) {
    return Column(
      children: [
        Text(
          "or connect with",
          style: AppStyles.bodySmall.copyWith(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: isLoading ? null : () => _handleGoogleAuth(signupViewModelProvider),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 16.r,
              backgroundColor: whiteColor,
              backgroundImage: const AssetImage(AppAssets.googleLogo),
              child: isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
