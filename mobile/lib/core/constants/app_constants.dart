class AppConstants {
  // App Info
  static const String appName = 'StudioBook';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Music Studio Booking Platform';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 15);
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxReviewLength = 500;
  
  // Booking
  static const int maxBookingDaysAhead = 30;
  static const int minBookingHours = 1;
  static const int maxBookingHours = 12;
  
  // Rating
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
}
