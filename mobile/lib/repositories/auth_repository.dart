import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    });

    return {
      'user': UserModel.fromJson(response['data']['user']),
      'token': response['data']['token'],
    };
  }

  /// Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    return {
      'user': UserModel.fromJson(response['data']['user']),
      'token': response['data']['token'],
    };
  }

  /// Logout
  Future<void> logout() async {
    await _api.post('/auth/logout');
  }

  /// Get current user
  Future<UserModel> getProfile() async {
    final response = await _api.get('/auth/me');
    return UserModel.fromJson(response['data']);
  }

  /// Update profile
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final response = await _api.put('/auth/profile', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });

    return UserModel.fromJson(response['data']);
  }

  /// Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put('/auth/password', data: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  /// Reset password
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    await _api.post('/auth/reset-password', data: {
      'token': token,
      'email': email,
      'password': password,
    });
  }
}
