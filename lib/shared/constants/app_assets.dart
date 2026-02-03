// lib/shared/constants/app_assets.dart

class AppAssets {
  // Base Directories
  static const String _basePng = 'assets/images/app_png/';
  static const String _baseSvg = 'assets/images/app_svg/';

  // --- SPLASH & AUTH SCREENS ---

  // Logos & Splash
  // Used in Splash Screen
  static const String logoIcon = '${_basePng}Ellipse 1302.png';
  // Used in Login/Signup background
  static const String vectorBackground1 = '${_basePng}Vector 1.png';
  static const String vectorBackground2 = '${_basePng}Vector 2.png';
  static const String loginbg = '${_basePng}Vector 3.png';
  // Additional Splash Vectors
  static const String splashVector1 = '${_basePng}Splash_Vector_1.png';
  static const String splashVector2 = '${_basePng}Splash_Vector_2.png';

  // Branding
  static const String libroText = '${_basePng}libro_text.png';
  static const String googleLogo = '${_basePng}Google_logo.png';

  // --- HOME / FEATURE ICONS ---

  // Main Action Icons (Circle Icons on Home)
  static const String buyIcon = '${_basePng}Buy.png';
  static const String rentIcon = '${_basePng}rent 1300.png';
  static const String sellIcon = '${_basePng}Sell.png';
  static const String exchangeIcon = '${_basePng}book_exchange_icon.png';
  static const String readIcon = '${_basePng}Read.png';

  // --- BOOKS & STORES (Dummy Data & Placeholders) ---

  // Book Covers (For Dummy Data Generation)
  static const String booksImg1 =
      '${_basePng}books_img_1.png'; // Used in headers
  static const String bookImage1 =
      '${_basePng}book_image_1.png'; // Norse Mythology
  static const String bookImage2 =
      '${_basePng}book_image_2.png'; // Never Ending Sky

  // Store Images
  static const String storeImagePlaceholder = '${_basePng}store_img.png';

  // --- UTILITY / PLACEHOLDERS ---

  // General Placeholders
  static const String placeholderImage = '${_basePng}placeholder_img1.png';
  static const String userProfilePlaceholder =
      '${_basePng}Rectangle 4292.png'; // Assuming this is the profile placeholder

  // SVG Assets
  static const String filterIcon = '${_baseSvg}filter_icon.svg';
}
