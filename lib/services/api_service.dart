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
  // Configure flutter_secure_storage with explicit WebOptions so it works
  // reliably on Flutter Web (uses IndexedDB + SubtleCrypto under the hood).
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'noors_attire_storage',
      publicKey: 'noors_attire_key',
    ),
  );

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

  /// Build headers for PUBLIC endpoints (e.g. products, homepage).
  /// If the user is logged in their token is included, but if secure storage
  /// throws we safely fall back to unauthenticated headers — that is acceptable
  /// for public GET requests that work either way.
  static Future<Map<String, String>> _publicHeaders() async {
    try {
      return await _headers();
    } catch (_) {
      // For public endpoints it's fine to proceed without a token.
      return {'Content-Type': 'application/json'};
    }
  }

  /// Build headers for AUTHENTICATED endpoints (e.g. POST /orders/).
  /// If the token is missing (user not logged in) or storage throws, this
  /// throws immediately so the caller can redirect to login — it never
  /// silently drops the token and sends an unauthenticated request.
  static Future<Map<String, String>> _authHeaders() async {
    // Let any storage exception propagate — do NOT swallow it.
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please log in to continue.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET request (works for both public and authenticated endpoints).
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    var url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    if (params != null) url = url.replace(queryParameters: params);

    try {
      final response = await http
          .get(url, headers: await _publicHeaders())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Backend not responding at ${AppConstants.baseUrl} — '
              'make sure the backend server is running (run_backend.bat).',
            ),
          );
      return _handle(response);
    } on Exception catch (e) {
      final msg = e.toString();
      // Convert Flutter Web "Failed to fetch" / "ClientException" into a
      // friendlier message that tells the developer what to do.
      if (msg.contains('Failed to fetch') ||
          msg.contains('ClientException') ||
          msg.contains('SocketException') ||
          msg.contains('Connection refused')) {
        throw Exception(
          'Cannot reach backend at ${AppConstants.baseUrl} — '
          'please start the backend server (run_backend.bat).',
        );
      }
      rethrow;
    }
  }

  /// POST request for PUBLIC or OPTIONAL-auth endpoints.
  /// (Used by login, signup, newsletter — no token required.)
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: await _publicHeaders(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  /// POST request for PROTECTED endpoints that REQUIRE authentication.
  /// Throws immediately (with a clear message) if the user is not logged in
  /// or if the token cannot be read — it never silently drops the token.
  static Future<dynamic> postAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    // _authHeaders() throws if token is missing — no silent fallback.
    final headers = await _authHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  /// PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: await _publicHeaders(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  /// DELETE request
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.delete(url, headers: await _publicHeaders());
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
    try {
      final token = await _getToken();
      return token != null;
    } catch (_) {
      return false;
    }
  }

  /// Subscribe email to newsletter
  static Future<dynamic> subscribeNewsletter(String email) async {
    return await post('/users/subscribe', {'email': email});
  }
}
