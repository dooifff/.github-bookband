import 'package:flutter/foundation.dart';

class AppConstants {
  // App Info
  static const String appName = 'StudioBook';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Music Studio Booking Platform';

  // API Configuration
  //
  // Base URL backend ditentukan dengan urutan prioritas:
  //   1. `--dart-define=API_BASE_URL=https://contoh.com/api/v1` saat build/run
  //   2. Nilai yang diisi pengguna dari layar login (disimpan di perangkat)
  //   3. Default per platform lewat [defaultApiBaseUrl]
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Default base URL backend bila tidak ada override.
  ///
  /// Di emulator Android host komputer dipetakan ke `10.0.2.2`, sehingga
  /// `localhost` tidak akan pernah menjangkau backend di komputer. Untuk
  /// perangkat fisik, jalankan dengan
  /// `--dart-define=API_BASE_URL=http://<IP-komputer>:8000/api/v1`.
  static String get defaultApiBaseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://localhost:8000/api/v1';
  }

  /// Base URL yang sedang dipakai aplikasi.
  ///
  /// Dimiliki bersama oleh [ApiService] dan kode lain yang membutuhkannya
  /// (mis. pendaftaran token FCM), sehingga override saat runtime ikut berlaku.
  static String baseUrl = defaultApiBaseUrl;

  /// Apakah [baseUrl] memakai default (bukan hasil override pengguna).
  static bool get isUsingDefaultBaseUrl => baseUrl == defaultApiBaseUrl;

  static const Duration apiTimeout = Duration(seconds: 15);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String apiBaseUrlKey = 'api_base_url';
  
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

  // Google Sign-In
  // Nilai diisi saat build/run, contoh:
  // flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}
