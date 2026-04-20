// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().loadHomeData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Navigation Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.white,
            elevation: 1,
            title: Text(
              AppConstants.appName,
              style: const TextStyle(
                fontFamily: 'Playfair',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textDark),
                onPressed: () => Navigator.pushNamed(context, '/products'),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppTheme.textDark,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: AppTheme.textDark,
                ),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroBanner(),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Shop by Category',
                  onSeeAll: () => Navigator.pushNamed(context, '/products'),
                ),
                const SizedBox(height: 16),
                const _CategoriesRow(),
                const SizedBox(height: 40),
                _SectionHeader(
                  title: 'Featured Collection',
                  onSeeAll: () => Navigator.pushNamed(context, '/products'),
                ),
                const SizedBox(height: 16),
                const _FeaturedCarousel(),
                const SizedBox(height: 40),
                _SectionHeader(
                  title: 'Bestsellers',
                  onSeeAll: () => Navigator.pushNamed(context, '/products'),
                ),
                const SizedBox(height: 16),
                const _BestsellersGrid(),
                const SizedBox(height: 40),
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 480,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C0A0A), Color(0xFF8B1A1A), Color(0xFFB5451B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Noor's Attire",
                  style: TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4A017),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Pashtun Heritage, Modern Style",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroButton(
                      label: 'Shop Dresses',
                      onTap: () => Navigator.pushNamed(context, '/products'),
                      filled: true,
                    ),
                    const SizedBox(width: 16),
                    _HeroButton(
                      label: 'Paint Shirts',
                      onTap: () => Navigator.pushNamed(context, '/products'),
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _HeroButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFD4A017) : Colors.transparent,
          border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : const Color(0xFFD4A017),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 6; j++) {
        final path = Path();
        final x = i * 80.0;
        final y = j * 100.0 + (i.isEven ? 0 : 50);
        path.moveTo(x, y - 20);
        path.lineTo(x + 15, y);
        path.lineTo(x, y + 20);
        path.lineTo(x - 15, y);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Section Header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See All →',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Categories Row ────────────────────────────────────────────────────────
class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CategoryCard(
            label: 'All',
            icon: '🛍️',
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          CategoryCard(
            label: 'Pashtun Dresses',
            icon: '👗',
            onTap: () => Navigator.pushNamed(
              context,
              '/products',
              arguments: AppConstants.categoryPashtunDress,
            ),
          ),
          CategoryCard(
            label: 'Paint Shirts',
            icon: '🎨',
            onTap: () => Navigator.pushNamed(
              context,
              '/products',
              arguments: AppConstants.categoryPaintShirt,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Featured Carousel ─────────────────────────────────────────────────────
class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().featured;

    if (products.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 320,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.75,
      ),
      items: products
          .map(
            (product) => ProductCard(
              product: product,
              onTap: () => Navigator.pushNamed(
                context,
                '/product',
                arguments: product.id,
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Bestsellers Grid ──────────────────────────────────────────────────────
class _BestsellersGrid extends StatelessWidget {
  const _BestsellersGrid();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().bestsellers;

    if (products.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onTap: () => Navigator.pushNamed(
          context,
          '/product',
          arguments: products[index].id,
        ),
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1C1C1C),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand name
          const Text(
            "Noor's Attire",
            style: TextStyle(
              fontFamily: 'Playfair',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4A017),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Authentic Pashtun Clothing — Made with Love",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 24),

          // Divider
          Container(width: double.infinity, height: 1, color: Colors.white12),

          const SizedBox(height: 24),

          // Contact info — clickable
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://maps.google.com/?q=Peshawar,KPK,Pakistan'),
            ),
            child: const Text(
              "📍 Peshawar, KPK, Pakistan",
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 2),
            ),
          ),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('tel:+923340588115')),
            child: const Text(
              "📞 +92-3340588115",
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 2),
            ),
          ),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('mailto:noor@noors-attire.com')),
            child: const Text(
              "✉️  noor@noors-attire.com",
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 2),
            ),
          ),

          const SizedBox(height: 24),

          // Copyright
          Text(
            "© 2024 Noor's Attire. All rights reserved.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
