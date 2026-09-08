// lib/services/recently_viewed_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/product_model.dart';
import 'product_service.dart';

class RecentlyViewedService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'recently_viewed_products';
  static const _maxItems = 10;

  /// Get list of recently viewed products (deduplicated)
  static Future<List<Product>> getRecentlyViewed() async {
    try {
      final jsonStr = await _storage.read(key: _key);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> idList = jsonDecode(jsonStr);
      final List<Product> products = [];

      for (final id in idList) {
        try {
          final p = await ProductService.getProductById(id.toString());
          products.add(p);
        } catch (_) {}
      }

      return products;
    } catch (_) {
      return [];
    }
  }

  /// Track a product view
  static Future<void> addViewedProduct(String productId) async {
    try {
      final jsonStr = await _storage.read(key: _key);
      List<String> idList = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        idList = List<String>.from(jsonDecode(jsonStr));
      }

      // Remove existing occurrence to place it at the front
      idList.remove(productId);
      idList.insert(0, productId);

      if (idList.length > _maxItems) {
        idList = idList.sublist(0, _maxItems);
      }

      await _storage.write(key: _key, value: jsonEncode(idList));
    } catch (_) {}
  }

  /// Clear recently viewed history
  static Future<void> clearHistory() async {
    await _storage.delete(key: _key);
  }
}
