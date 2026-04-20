// lib/models/order_model.dart

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? size;
  final String? color;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.size,
    this.color,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'price': price,
    'size': size,
    'color': color,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'] ?? '',
    productName: json['product_name'] ?? '',
    quantity: json['quantity'] ?? 1,
    price: (json['price'] ?? 0).toDouble(),
    size: json['size'],
    color: json['color'],
  );

  double get subtotal => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'cash_on_delivery',
      createdAt: json['created_at'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'confirmed':
        return '✅ Confirmed';
      case 'shipped':
        return '🚚 Shipped';
      case 'delivered':
        return '📦 Delivered';
      case 'cancelled':
        return '❌ Cancelled';
      default:
        return status;
    }
  }

  String get formattedTotal => 'PKR ${totalAmount.toStringAsFixed(0)}';
}
