// lib/main.dart
//
// App entry point. Sets up:
// 1. Provider (state management)
// 2. Theme
// 3. Routes (navigation)

import 'package:flutter/material.dart';
import 'package:frontend/screens/product/product_detail.dart';
import 'package:frontend/screens/product/product_list.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(const NoofsAttireApp());
}

class NoofsAttireApp extends StatelessWidget {
  const NoofsAttireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // MultiProvider lets us provide multiple state managers at once.
      // They're available to every widget in the tree below this point.
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: "Noor's Attire",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // ── Named Routes ──────────────────────────────────────────────────
        // Use Navigator.pushNamed(context, '/cart') to navigate
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/products': (context) => const ProductListScreen(),
          '/cart': (context) => const CartScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen(),
        },

        // For routes that need parameters (e.g. product ID):
        onGenerateRoute: (settings) {
          if (settings.name == '/product') {
            final productId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            );
          }
          return null;
        },
      ),
    );
  }
}
