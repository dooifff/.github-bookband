import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';

/// Pembungkus google_sign_in 7.x.
///
/// Inisialisasi hanya sekali, lalu [getIdToken] dipakai untuk mengambil ID token
/// yang diverifikasi backend di POST /api/v1/auth/google.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// True bila minimal satu client ID sudah diisi lewat --dart-define.
  bool get isConfigured =>
      AppConstants.googleServerClientId.isNotEmpty ||
      AppConstants.googleWebClientId.isNotEmpty ||
      AppConstants.googleIosClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      await _googleSignIn.initialize(
        clientId: _orNull(AppConstants.googleWebClientId),
        serverClientId: _orNull(AppConstants.googleServerClientId),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _googleSignIn.initialize(
        clientId: _orNull(AppConstants.googleIosClientId),
        serverClientId: _orNull(AppConstants.googleServerClientId),
      );
    } else {
      // Android memakai serverClientId (client ID tipe Web) agar mendapat ID token.
      await _googleSignIn.initialize(
        serverClientId: _orNull(AppConstants.googleServerClientId),
      );
    }

    _initialized = true;
  }

  /// Ambil ID token Google.
  ///
  /// Melempar [GoogleSignInException] bila pengguna membatalkan dialog.
  Future<String> getIdToken() async {
    await _ensureInitialized();

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final String? idToken = account.authentication.idToken;

    if (idToken == null) {
      throw StateError(
        'Google tidak mengirimkan ID token. Periksa konfigurasi client ID aplikasi.',
      );
    }

    return idToken;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }

  String? _orNull(String value) => value.isEmpty ? null : value;
}
