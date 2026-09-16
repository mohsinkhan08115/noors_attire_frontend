import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/wishlist_provider.dart';
import 'package:frontend/screens/product/product_detail.dart';
import 'package:frontend/widgets/product_card.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  const sampleProduct = Product(
    id: 'prod-456',
    name: 'Silk Velvet Peshawari Turban',
    description: 'Traditional ceremonial silk velvet turban.',
    price: 12000.0,
    category: 'turbans',
    sizes: ['Free Size'],
    colors: ['Emerald Green', 'Royal Navy'],
    stock: 3,
    imageUrls: ['https://example.com/turban1.jpg'],
    isFeatured: true,
    isBestseller: false,
    tags: ['turbans', 'ceremonial'],
  );

  testWidgets('Clicking ProductCard navigates to ProductDetailScreen without crashing', (tester) async {
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
          onGenerateRoute: (settings) {
            if (settings.name == '/product') {
              String productId = '';
              Product? initialProduct;
              if (settings.arguments is Product) {
                initialProduct = settings.arguments as Product;
                productId = initialProduct.id;
              } else if (settings.arguments is String) {
                productId = settings.arguments as String;
              }
              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: productId,
                  initialProduct: initialProduct,
                ),
              );
            }
            return null;
          },
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 380,
                child: Builder(
                  builder: (context) => ProductCard(
                    product: sampleProduct,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/product',
                      arguments: sampleProduct,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.byType(ProductCard), findsOneWidget);

    // Simulate mouse hover
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(ProductCard)));
    await tester.pump();

    // Click product card
    await tester.tap(find.byType(ProductCard));
    await tester.pump(); // start route transition
    await tester.pump(const Duration(milliseconds: 350)); // complete route transition

    // Verify ProductDetailScreen is displayed
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProductDetailScreen),
        matching: find.text('Silk Velvet Peshawari Turban'),
      ),
      findsOneWidget,
    );
    expect(find.text('ADD TO SHOPPING CART'), findsOneWidget);
  });
}
