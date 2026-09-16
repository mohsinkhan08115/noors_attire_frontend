import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/wishlist_provider.dart';
import 'package:frontend/screens/product/product_detail.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  const sampleProduct = Product(
    id: 'prod-123',
    name: 'Royal Peshawari Chappal',
    description: 'Handcrafted luxury leather footwear.',
    price: 9500.0,
    salePrice: 7600.0,
    sku: 'RPC-001',
    category: 'footwear',
    sizes: ['8', '9', '10', '11'],
    colors: ['Burgundy', 'Mustard Gold', 'Deep Charcoal'],
    stock: 5,
    imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
    isFeatured: true,
    isBestseller: true,
    tags: ['footwear', 'heritage'],
  );

  testWidgets('ProductDetailScreen renders loading state properly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDetailScreen(productId: 'non-existent'),
        ),
      ),
    );

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('ProductDetailScreen renders desktop layout with initialProduct', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDetailScreen(
            productId: 'prod-123',
            initialProduct: sampleProduct,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Royal Peshawari Chappal'), findsOneWidget);
    expect(find.text('ADD TO SHOPPING CART'), findsOneWidget);
    expect(find.text('Handcrafted luxury leather footwear.'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen renders mobile layout with initialProduct', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDetailScreen(
            productId: 'prod-123',
            initialProduct: sampleProduct,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Royal Peshawari Chappal'), findsOneWidget);
    expect(find.text('ADD TO SHOPPING CART'), findsOneWidget);
  });
}
