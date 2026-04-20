// lib/core/constants/app_constants.dart
//
// Central place for all app-wide constants.
// Change the baseUrl here to switch between local and production.

class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  // Change this to your Vercel backend URL after deployment
  static const String baseUrl = 'https://noors-attire.vercel.app';

  // For local development:
  // static const String baseUrl = 'http://127.0.0.1:8000';
  

  // ── Storage Keys ─────────────────────────────────────────────────────────
  // Keys used with flutter_secure_storage to save the JWT token locally
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName = "Noor's Attire";
  static const String tagline = "Pashtun Heritage, Modern Style";

  // ── Categories ───────────────────────────────────────────────────────────
  static const String categoryPashtunDress = 'pashtun_dress';
  static const String categoryPaintShirt = 'paint_shirt';

  // ── Currency ─────────────────────────────────────────────────────────────
  static const String currencySymbol = 'PKR';
}
