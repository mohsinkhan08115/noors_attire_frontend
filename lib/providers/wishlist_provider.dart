// lib/providers/wishlist_provider.dart

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;
  bool _requiresLogin = false;

  Map<String, List<String>> _collections = {
    "Wedding": [],
    "Eid": [],
    "Casual": [],
    "Gifts": [],
    "Favorites": [],
    "Maybe Later": []
  };
  String _selectedCollection = "Favorites";

  List<Product> get items => _items;
  bool get isLoading => _isLoading;
  bool get requiresLogin => _requiresLogin;
  bool get isEmpty => _items.isEmpty;
  int get count => _items.length;
  Map<String, List<String>> get collections => _collections;
  String get selectedCollection => _selectedCollection;

  List<Product> get filteredCollectionItems {
    if (_selectedCollection == "All" || !_collections.containsKey(_selectedCollection)) {
      return _items;
    }
    final allowedIds = _collections[_selectedCollection] ?? [];
    if (allowedIds.isEmpty) return _items; // Fallback to all items if empty
    return _items.where((p) => allowedIds.contains(p.id)).toList();
  }

  bool isWishlisted(String productId) =>
      _items.any((p) => p.id == productId);

  void setCollection(String name) {
    _selectedCollection = name;
    notifyListeners();
  }

  Future<void> createCollection(String name) async {
    if (name.trim().isEmpty) return;
    final trimmed = name.trim();
    if (!_collections.containsKey(trimmed)) {
      _collections[trimmed] = [];
      _selectedCollection = trimmed;
      notifyListeners();
      try {
        if (await ApiService.isLoggedIn()) {
          await ApiService.post('/wishlist/collections', {'name': trimmed});
        }
      } catch (_) {}
    }
  }

  Future<void> moveItemToCollection(String productId, String collectionName) async {
    if (!_collections.containsKey(collectionName)) {
      _collections[collectionName] = [];
    }
    if (!_collections[collectionName]!.contains(productId)) {
      _collections[collectionName]!.add(productId);
      notifyListeners();
      try {
        if (await ApiService.isLoggedIn()) {
          await ApiService.post('/wishlist/collections/$collectionName/items', {
            'product_id': productId,
          });
        }
      } catch (_) {}
    }
  }

  Future<void> load() async {
    if (!await ApiService.isLoggedIn()) {
      _items = [];
      _requiresLogin = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _requiresLogin = false;
    notifyListeners();
    try {
      _items = await WishlistService.getWishlist();
      final res = await ApiService.get('/wishlist/collections');
      if (res is Map) {
        _collections = Map<String, List<String>>.from(
          res.map((k, v) => MapEntry(k.toString(), List<String>.from(v))),
        );
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _items = [];
    _requiresLogin = false;
    notifyListeners();
  }

  Future<bool> toggle(Product product) async {
    if (!await ApiService.isLoggedIn()) {
      _requiresLogin = true;
      notifyListeners();
      return false;
    }

    final wasWishlisted = isWishlisted(product.id);
    final previous = List<Product>.from(_items);

    if (wasWishlisted) {
      _items = _items.where((p) => p.id != product.id).toList();
    } else {
      _items = [..._items, product];
    }
    notifyListeners();

    try {
      _items = wasWishlisted
          ? await WishlistService.removeFromWishlist(product.id)
          : await WishlistService.addToWishlist(product.id);
      notifyListeners();
      return true;
    } catch (_) {
      _items = previous;
      notifyListeners();
      return false;
    }
  }
}
