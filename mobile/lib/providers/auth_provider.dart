import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/google_sign_in_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  AuthProvider() : _authRepository = AuthRepository(ApiService());

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get error => _error;

  /// Initialize - check for stored token
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiService().getToken();
      if (token != null) {
        _token = token;
        _user = await _authRepository.getProfile();
      }
    } catch (e) {
      // Token invalid or expired
      await _clearAuth();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      _user = result['user'];
      _token = result['token'];
      await ApiService().setToken(_token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      _user = result['user'];
      _token = result['token'];
      await ApiService().setToken(_token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login/register lewat Google
  ///
  /// [role] hanya dipakai bila email Google belum pernah terdaftar.
  Future<bool> loginWithGoogle({String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await GoogleSignInService.instance.getIdToken();
      final result = await _authRepository.googleLogin(
        idToken: idToken,
        role: role,
      );

      _user = result['user'];
      _token = result['token'];
      await ApiService().setToken(_token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      // Pembatalan oleh pengguna bukan error yang perlu ditampilkan.
      _error = e.code == GoogleSignInExceptionCode.canceled
          ? null
          : (e.description ?? 'Login dengan Google gagal');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } catch (e) {
      // Ignore error on logout
    } finally {
      await _clearAuth();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get profile
  Future<void> getProfile() async {
    try {
      _user = await _authRepository.getProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.forgotPassword(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password memakai token yang dikirim ke email
  Future<bool> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(
        token: token,
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear auth data
  Future<void> _clearAuth() async {
    _user = null;
    _token = null;
    await ApiService().removeToken();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
