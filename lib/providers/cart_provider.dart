// lib/providers/cart_provider.dart

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

  double get subtotal => product.effectivePrice * quantity;

  Map<String, dynamic> toOrderItemJson() => {
    'product_id': product.id,
    'product_name': product.name,
    'quantity': quantity,
    'price': product.effectivePrice,
    'size': selectedSize,
    'color': selectedColor,
  };
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal => 'PKR ${totalAmount.toStringAsFixed(0)}';

  bool get isEmpty => _items.isEmpty;

  void addItem(Product product, {String? size, String? color}) {
    final key = '${product.id}_${size}_$color';

    if (_items.containsKey(key)) {
      _items[key]!.quantity++;
    } else {
      _items[key] = CartItem(
        product: product,
        quantity: 1,
        selectedSize: size,
        selectedColor: color,
      );
    }
    notifyListeners();
  }

  /// Add multiple products as a complete look bundle
  void addLookBundle(List<Product> bundle) {
    for (final product in bundle) {
      addItem(product);
    }
  }

  void decrementItem(String key) {
    if (!_items.containsKey(key)) return;

    if (_items[key]!.quantity <= 1) {
      _items.remove(key);
    } else {
      _items[key]!.quantity--;
    }
    notifyListeners();
  }

  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Place order — sends cart to backend API with optional gift_info
  Future<OrderModel> checkout({
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String province,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
    Map<String, dynamic>? giftInfo,
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
      if (giftInfo != null) 'gift_info': giftInfo,
    };

    final response = await ApiService.post('/orders/', orderData);
    final order = OrderModel.fromJson(response);

    clear();
    return order;
  }
}
