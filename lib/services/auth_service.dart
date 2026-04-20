// lib/services/auth_service.dart
//
// Handles login, signup, and logout on the Flutter side.
// After successful auth, saves the JWT token securely.

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  /// Register new account.
  /// Returns the user model on success.
  static Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await ApiService.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    });

    // Save the JWT token for future requests
    await ApiService.saveToken(data['access_token']);
    return UserModel.fromJson(data['user']);
  }

  /// Log in with email and password.
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    await ApiService.saveToken(data['access_token']);
    return UserModel.fromJson(data['user']);
  }

  /// Get current user profile (requires valid token).
  static Future<UserModel?> getCurrentUser() async {
    try {
      final data = await ApiService.get('/auth/me');
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
  
  /// Log out: clear saved token.
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}
