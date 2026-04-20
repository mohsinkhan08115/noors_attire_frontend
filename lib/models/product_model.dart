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
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final List<String> imageUrls;
  final bool isFeatured;
  final bool isBestseller;
  final List<String> tags;
  final String? createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.sizes,
    required this.colors,
    required this.stock,
    required this.imageUrls,
    required this.isFeatured,
    required this.isBestseller,
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
      category: json['category'] ?? '',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      stock: json['stock'] ?? 0,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      isFeatured: json['is_featured'] ?? false,
      isBestseller: json['is_bestseller'] ?? false,
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

  /// Formatted price string
  String get formattedPrice => 'PKR ${price.toStringAsFixed(0)}';

  /// Category display name
  String get categoryDisplayName {
    switch (category) {
      case 'pashtun_dress':
        return 'Pashtun Dress';
      case 'paint_shirt':
        return 'Paint Shirt';
      default:
        return category;
    }
  }
}
