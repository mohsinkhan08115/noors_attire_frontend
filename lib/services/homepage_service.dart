// lib/services/homepage_service.dart

import '../models/homepage_config.dart';
import 'api_service.dart';

class HomepageService {
  static Future<HomepageConfig> getHomepage() async {
    final data = await ApiService.get('/homepage/');
    return HomepageConfig.fromJson(data as Map<String, dynamic>);
  }
}
