// lib/services/product_service.dart
//
// Calls product-related API endpoints and returns typed Dart objects.
// The provider layer calls this service and notifies the UI of changes.

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
}
