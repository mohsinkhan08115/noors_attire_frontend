// lib/providers/cart_provider.dart
//
// CartProvider manages the shopping cart state.
// It extends ChangeNotifier, which means whenever the cart changes,
// all widgets listening to this provider will rebuild automatically.
//
// How Provider works:
// 1. Wrap your app in ChangeNotifierProvider(create: (_) => CartProvider())
// 2. In any widget: Provider.of<CartProvider>(context) to read state
// 3. Call cart.addItem(product) to trigger rebuild
//
// The cart lives in memory — refresh clears it.
// For persistence, save to SharedPreferences or send to backend.

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class CartItem {
  final Product product;
  int quantity;
  final String? selectedSize;
  final String? selectedColor;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.selectedColor,
  });

  double get subtotal => product.price * quantity;

  /// Convert cart item to order item format for API
  Map<String, dynamic> toOrderItemJson() => {
    'product_id': product.id,
    'product_name': product.name,
    'quantity': quantity,
    'price': product.price,
    'size': selectedSize,
    'color': selectedColor,
  };
}

class CartProvider extends ChangeNotifier {
  // Internal cart storage: product ID → CartItem
  final Map<String, CartItem> _items = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  /// All items in the cart
  List<CartItem> get items => _items.values.toList();

  /// Total number of individual products (for badge)
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal => 'PKR ${totalAmount.toStringAsFixed(0)}';

  bool get isEmpty => _items.isEmpty;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Add a product to cart (or increment quantity if already there)
  void addItem(Product product, {String? size, String? color}) {
    final key = '${product.id}_${size}_$color';

    if (_items.containsKey(key)) {
      // Already in cart → just increment
      _items[key]!.quantity++;
    } else {
      // New item
      _items[key] = CartItem(
        product: product,
        quantity: 1,
        selectedSize: size,
        selectedColor: color,
      );
    }

    notifyListeners(); // ← This triggers UI rebuild everywhere
  }

  /// Remove one quantity of an item
  void decrementItem(String key) {
    if (!_items.containsKey(key)) return;

    if (_items[key]!.quantity <= 1) {
      _items.remove(key);
    } else {
      _items[key]!.quantity--;
    }

    notifyListeners();
  }

  /// Remove item entirely from cart
  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  /// Clear the entire cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Place order — sends cart to backend API
  Future<OrderModel> checkout({
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String province,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
  }) async {
    if (_items.isEmpty) throw Exception('Cart is empty');

    final orderData = {
      'items': _items.values.map((i) => i.toOrderItemJson()).toList(),
      'shipping_address': {
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'city': city,
        'province': province,
      },
      'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    };

    final response = await ApiService.post('/orders/', orderData);
    final order = OrderModel.fromJson(response);

    // Clear cart after successful order
    clear();

    return order;
  }
}
