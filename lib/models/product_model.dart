// lib/models/product_model.dart
//
// The Product model mirrors the data structure from our FastAPI backend.
// fromJson() converts API response (Map) to a Dart object.
// toJson() converts back to Map for sending to the API.

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final String? sku;
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final List<String> imageUrls;
  final bool isFeatured;
  final bool isBestseller;
  final bool showOnHome;
  final int homeOrder;
  final List<String> tags;
  final String? createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    this.sku,
    required this.category,
    required this.sizes,
    required this.colors,
    required this.stock,
    required this.imageUrls,
    required this.isFeatured,
    required this.isBestseller,
    this.showOnHome = false,
    this.homeOrder = 0,
    required this.tags,
    this.createdAt,
  });

  /// Convert API JSON response to Product object.
  /// Called when we receive data from the backend.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      salePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : null,
      sku: json['sku'],
      category: json['category'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      stock: json['stock'] ?? 0,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      isFeatured: json['is_featured'] ?? false,
      isBestseller: json['is_bestseller'] ?? false,
      showOnHome: json['show_on_home'] ?? false,
      homeOrder: json['home_order'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['created_at'],
    );
  }

  /// Convenience getter for the first image (or a placeholder)
  String get primaryImage => imageUrls.isNotEmpty
      ? imageUrls.first
      : 'https://via.placeholder.com/400x600';

  /// Whether the product is in stock
  bool get inStock => stock > 0;

  /// Formatted price string (original/list price)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(0)}';

  /// Whether the product currently has an active discount
  bool get isOnSale => salePrice != null && salePrice! < price;

  /// The price to actually charge/display prominently
  double get effectivePrice => isOnSale ? salePrice! : price;

  /// Formatted current price (sale price when on sale, else list price)
  String get formattedEffectivePrice => 'PKR ${effectivePrice.toStringAsFixed(0)}';

  /// Discount percentage, rounded, or 0 when not on sale
  int get discountPercent =>
      isOnSale ? (((price - salePrice!) / price) * 100).round() : 0;

  /// Category display name
  String get categoryDisplayName {
    switch (category.toLowerCase().trim()) {
      case 'pashtun_dress':
        return 'Pashtun Dress';
      case 'paint_shirt':
        return 'Paint Shirt';
      case 'clothing':
        return 'Clothing';
      case 'accessories':
        return 'Accessories';
      case 'wallets':
      case 'wallet':
        return 'Wallet';
      case 'watches':
      case 'watch':
        return 'Watch';
      case 'perfumes':
      case 'perfume':
        return 'Perfume';
      case 'lighters':
      case 'lighter':
        return 'Lighter';
      case 'caps':
      case 'cap':
        return 'Cap';
      case 'sunglasses':
        return 'Sunglasses';
      case 'bags':
      case 'bag':
        return 'Bag';
      case 'belts':
      case 'belt':
        return 'Belt';
      case 'shoes':
      case 'shoe':
        return 'Shoes';
      case 'keychains':
      case 'keychain':
        return 'Keychain';
      case 'trending':
        return 'Trending';
      default:
        if (category.isEmpty) return 'Product';
        return category
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
