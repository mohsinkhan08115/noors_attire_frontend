// lib/services/api_service.dart
//
// Central HTTP client for all API calls to our FastAPI backend.
// All other services use this class to make requests.
//
// Why a central service?
// - One place to set base URL, headers, error handling
// - Easy to switch between dev/prod backend
// - All auth token injection happens here

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  /// Read JWT token from secure storage.
  /// Returns null if user is not logged in.
  static Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  /// Build request headers.
  /// Automatically adds Authorization header if user is logged in.
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle HTTP response — parse JSON or throw error.
  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    // Try to parse error message from backend
    try {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Server error ${response.statusCode}');
    } catch (_) {
      throw Exception('Server error ${response.statusCode}');
    }
  }

  /// GET request
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    var url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    if (params != null) url = url.replace(queryParameters: params);

    final response = await http.get(url, headers: await _headers());
    return _handle(response);
  }

  /// POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  /// PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  /// DELETE request
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.delete(url, headers: await _headers());
    return _handle(response);
  }

  /// Save token after login/signup
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Clear token on logout
  static Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }
}
