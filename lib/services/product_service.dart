// lib/services/product_service.dart

import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  /// Fetch all products with optional filters.
  static Future<List<Product>> getProducts({
    String? category,
    bool? featured,
    bool? bestseller,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (category != null) params['category'] = category;
    if (featured != null) params['featured'] = featured.toString();
    if (bestseller != null) params['bestseller'] = bestseller.toString();

    final data = await ApiService.get('/products/', params: params);
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  /// Fetch a single product by ID.
  static Future<Product> getProductById(String id) async {
    final data = await ApiService.get('/products/$id');
    return Product.fromJson(data);
  }

  /// Search products by keyword.
  static Future<List<Product>> searchProducts(String query) async {
    final data = await ApiService.get('/products/search', params: {'q': query});
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  /// Get "Complete The Look" bundle recommendation items.
  static Future<List<Product>> getCompleteTheLook(String productId) async {
    try {
      final data = await ApiService.get('/products/$productId/complete-the-look');
      if (data is List && data.isNotEmpty) {
        return data.map((p) => Product.fromJson(p)).toList();
      }
    } catch (_) {}

    // Fallback: return complementary products from catalog
    final all = await getProducts(limit: 10);
    return all.where((p) => p.id != productId).take(3).toList();
  }

  /// Get smart recommendations (You May Also Like).
  static Future<List<Product>> getRecommendations(String productId) async {
    try {
      final data = await ApiService.get('/products/$productId/recommendations');
      if (data is List && data.isNotEmpty) {
        return data.map((p) => Product.fromJson(p)).toList();
      }
    } catch (_) {}

    // Fallback: return catalog products
    final all = await getProducts(limit: 10);
    return all.where((p) => p.id != productId).take(4).toList();
  }

  /// Request back in stock or price drop notification.
  static Future<dynamic> requestNotification(
    String productId,
    String email,
    String notifyType,
  ) async {
    return await ApiService.post('/products/$productId/notify', {
      'email': email,
      'notify_type': notifyType,
    });
  }

  /// Get approved community styled fashion photos.
  static Future<List<dynamic>> getCommunityGallery() async {
    return await ApiService.get('/products/community/gallery');
  }

  /// Submit customer styled photo for approval.
  static Future<dynamic> submitCommunityPhoto(Map<String, dynamic> body) async {
    return await ApiService.post('/products/community/gallery', body);
  }
}
