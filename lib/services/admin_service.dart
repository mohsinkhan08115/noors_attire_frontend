// lib/services/admin_service.dart

import 'api_service.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await ApiService.get('/admin/dashboard/stats');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAllOrders({String? status}) async {
    final params = status != null ? {'status': status} : null;
    final data = await ApiService.get('/admin/orders', params: params);
    return data as List;
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await ApiService.put('/admin/orders/$orderId/status', {'status': status});
  }

  static Future<List<dynamic>> getAllUsers() async {
    final data = await ApiService.get('/admin/users');
    return data as List;
  }

  static Future<void> updateUserRole(String userId, String role) async {
    await ApiService.put('/admin/users/$userId/role', {'role': role});
  }

  static Future<void> toggleUserBlock(String userId, bool blocked) async {
    await ApiService.put('/admin/users/$userId/block', {'blocked': blocked});
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final data = await ApiService.get('/admin/settings');
    return data as Map<String, dynamic>;
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    await ApiService.put('/admin/settings', settings);
  }
}
