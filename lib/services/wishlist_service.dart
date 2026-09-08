// lib/services/wishlist_service.dart
//
// Calls the wishlist API endpoints. Requires the user to be logged in —
// the backend returns 401 otherwise, which callers should handle.

import '../models/product_model.dart';
import 'api_service.dart';

class WishlistService {
  /// Fetch the current user's wishlisted products (full details).
  static Future<List<Product>> getWishlist() async {
    final data = await ApiService.get('/wishlist/');
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  /// Add a product to the wishlist. Returns the updated wishlist.
  static Future<List<Product>> addToWishlist(String productId) async {
    final data = await ApiService.post('/wishlist/$productId', {});
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  /// Remove a product from the wishlist. Returns the updated wishlist.
  static Future<List<Product>> removeFromWishlist(String productId) async {
    final data = await ApiService.delete('/wishlist/$productId');
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }
}
