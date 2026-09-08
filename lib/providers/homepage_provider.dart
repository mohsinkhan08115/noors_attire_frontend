// lib/providers/homepage_provider.dart
//
// Holds the admin-editable homepage configuration. Starts from the
// same fallback content the homepage always had, so a slow or failed
// fetch never blanks the page — it just shows the previous defaults.

import 'package:flutter/material.dart';
import '../models/homepage_config.dart';
import '../services/homepage_service.dart';

class HomepageProvider extends ChangeNotifier {
  HomepageConfig _config = HomepageConfig.fallback;
  bool _isLoading = false;

  HomepageConfig get config => _config;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await HomepageService.getHomepage();
    } catch (_) {
      // Keep the fallback config — the homepage still renders normally.
    }
    _isLoading = false;
    notifyListeners();
  }
}
