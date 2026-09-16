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
  List<Product> _homeProducts = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _isHomeLoading = false;
  String? _error;
  String? _homeError;
  String _selectedCategory = 'all';

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isHomeLoading => _isHomeLoading;
  String? get error => _error;
  String? get homeError => _homeError;
  List<Product> get products => _allProducts;
  List<Product> get featured => _featured;
  List<Product> get bestsellers => _bestsellers;
  List<Product> get homeProducts => _homeProducts;
  List<Product> get searchResults => _searchResults;
  String get selectedCategory => _selectedCategory;

  /// Products filtered by selected category
  List<Product> get filteredProducts {
    if (_selectedCategory == 'all') return _allProducts;
    return _allProducts.where((p) => p.category == _selectedCategory).toList();
  }

  /// Formats category key into a display title (e.g. pashtun_dress -> Pashtun Dresses)
  static String formatCategoryTitle(String category) {
    switch (category.toLowerCase().trim()) {
      case 'pashtun_dress':
        return 'Pashtun Dresses';
      case 'paint_shirt':
        return 'Paint Shirts';
      case 'clothing':
        return 'Signature Clothing';
      case 'accessories':
        return 'Fashion Accessories';
      case 'wallets':
      case 'wallet':
        return 'Luxury Wallets';
      case 'watches':
      case 'watch':
        return 'Royal Watches';
      case 'perfumes':
      case 'perfume':
        return 'Signature Perfumes';
      case 'lighters':
      case 'lighter':
        return 'Luxury Lighters';
      case 'caps':
      case 'cap':
        return 'Heritage Caps';
      case 'sunglasses':
        return 'Designer Sunglasses';
      case 'bags':
      case 'bag':
        return 'Premium Bags';
      case 'belts':
      case 'belt':
        return 'Handcrafted Belts';
      case 'shoes':
      case 'shoe':
        return 'Artisan Footwear';
      case 'keychains':
      case 'keychain':
        return 'Artisan Keychains';
      case 'trending':
        return 'Trending Now';
      default:
        if (category.isEmpty) return 'Collection';
        return category
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Returns a subtitle for each category
  static String getCategorySubtitle(String category) {
    switch (category.toLowerCase().trim()) {
      case 'pashtun_dress':
        return 'Authentic hand-embroidered royal attire';
      case 'paint_shirt':
        return 'Artisan hand-painted shirts crafted with distinction';
      case 'clothing':
        return 'Refined traditional and contemporary attire';
      case 'accessories':
        return 'Handcrafted luxury essentials to complete your signature look';
      case 'wallets':
      case 'wallet':
        return 'Handcrafted leather & artisanal luxury wallets';
      case 'watches':
      case 'watch':
        return 'Precision timepieces with timeless sophistication';
      case 'perfumes':
      case 'perfume':
        return 'Opulent oriental and signature artisanal fragrances';
      case 'lighters':
      case 'lighter':
        return 'Exquisite collector and luxury engraved lighters';
      case 'caps':
      case 'cap':
        return 'Traditional and contemporary handcrafted caps';
      case 'sunglasses':
        return 'Premium eyewear styled for elegance and distinction';
      case 'bags':
      case 'bag':
        return 'Sophisticated leather bags and everyday totes';
      case 'belts':
      case 'belt':
        return 'Top-grain leather belts with custom brass buckles';
      case 'shoes':
      case 'shoe':
        return 'Hand-stitched luxury Peshawari chappals and leather shoes';
      case 'keychains':
      case 'keychain':
        return 'Signature custom and bespoke key accessories';
      case 'trending':
        return 'The most sought-after unique lifestyle pieces';
      default:
        return 'Curated pieces crafted with heritage precision';
    }
  }

  /// Unique categories found across products
  List<String> get allCategories {
    final Set<String> cats = {};
    for (final p in _allProducts) {
      if (p.category.trim().isNotEmpty) {
        cats.add(p.category.trim());
      }
    }
    for (final p in _homeProducts) {
      if (p.category.trim().isNotEmpty) {
        cats.add(p.category.trim());
      }
    }
    return cats.toList();
  }

  /// Products grouped by category for the Home Screen.
  /// Preserves stable ordering: clothing, lifestyle accessories, trending, then alphabetical.
  Map<String, List<Product>> get homeProductsByCategory {
    final Map<String, List<Product>> grouped = {};
    final Set<String> seenIds = {};

    // 1. Group from _homeProducts first (respects show_on_home & home_order)
    for (final product in _homeProducts) {
      final cat = product.category.trim();
      if (cat.isEmpty) continue;
      grouped.putIfAbsent(cat, () => []).add(product);
      seenIds.add(product.id);
    }

    // 2. Add any additional products from _allProducts
    for (final product in _allProducts) {
      final cat = product.category.trim();
      if (cat.isEmpty || seenIds.contains(product.id)) continue;
      grouped.putIfAbsent(cat, () => []).add(product);
      seenIds.add(product.id);
    }

    // 3. Stable ordering: clothing, lifestyle accessories, trending, then alphabetical
    const preferredOrder = [
      'pashtun_dress',
      'paint_shirt',
      'clothing',
      'watches',
      'watch',
      'perfumes',
      'perfume',
      'wallets',
      'wallet',
      'caps',
      'cap',
      'sunglasses',
      'bags',
      'bag',
      'belts',
      'belt',
      'shoes',
      'shoe',
      'lighters',
      'lighter',
      'keychains',
      'keychain',
      'accessories',
      'trending',
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final idxA = preferredOrder.indexOf(a);
        final idxB = preferredOrder.indexOf(b);
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return a.compareTo(b);
      });

    final Map<String, List<Product>> result = {};
    for (final key in sortedKeys) {
      final prods = grouped[key]!;
      if (prods.isNotEmpty) {
        result[key] = prods;
      }
    }
    return result;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Load products configured for the Home Screen
  Future<void> loadHomeProducts() async {
    _isHomeLoading = true;
    _homeError = null;
    notifyListeners();
    try {
      _homeProducts = await ProductService.getHomeProducts();
      _homeError = null;
    } catch (e) {
      _homeError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }

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
      final items = await ProductService.getProducts(featured: true);
      if (items.isNotEmpty) {
        _featured = items;
      } else if (_allProducts.isNotEmpty) {
        _featured = _allProducts.take(8).toList();
      }
      notifyListeners();
    } catch (e) {
      // Silently fail — homepage still works without featured
    }
  }

  /// Load bestsellers for homepage
  Future<void> loadBestsellers() async {
    try {
      final items = await ProductService.getProducts(bestseller: true);
      if (items.isNotEmpty) {
        _bestsellers = items;
      } else if (_allProducts.isNotEmpty) {
        _bestsellers = _allProducts.where((p) => p.isFeatured).take(8).toList();
        if (_bestsellers.isEmpty) {
          _bestsellers = _allProducts.take(8).toList();
        }
      }
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  /// Load homepage data in parallel (faster)
  Future<void> loadHomeData() async {
    await Future.wait([
      loadHomeProducts(),
      loadProducts(),
    ]);
    await Future.wait([
      loadFeatured(),
      loadBestsellers(),
    ]);
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
