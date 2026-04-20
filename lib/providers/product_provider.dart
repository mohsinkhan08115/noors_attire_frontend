// lib/providers/product_provider.dart
//
// Manages product list state for the entire app.
// Fetches from the API and caches locally so we don't re-fetch on every navigation.

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _featured = [];
  List<Product> _bestsellers = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Product> get featured => _featured;
  List<Product> get bestsellers => _bestsellers;
  List<Product> get searchResults => _searchResults;
  String get selectedCategory => _selectedCategory;

  /// Products filtered by selected category
  List<Product> get filteredProducts {
    if (_selectedCategory == 'all') return _allProducts;
    return _allProducts.where((p) => p.category == _selectedCategory).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Load all products for the product list page
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      _allProducts = await ProductService.getProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Load featured products for the homepage
  Future<void> loadFeatured() async {
    try {
      _featured = await ProductService.getProducts(featured: true);
      notifyListeners();
    } catch (e) {
      // Silently fail — homepage still works without featured
    }
  }

  /// Load bestsellers for homepage
  Future<void> loadBestsellers() async {
    try {
      _bestsellers = await ProductService.getProducts(bestseller: true);
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  /// Load homepage data in parallel (faster)
  Future<void> loadHomeData() async {
    await Future.wait([loadFeatured(), loadBestsellers()]);
  }

  /// Filter product list by category
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Search products
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      _searchResults = await ProductService.searchProducts(query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
