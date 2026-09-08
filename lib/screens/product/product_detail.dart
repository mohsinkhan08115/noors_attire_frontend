// lib/screens/product/product_detail.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animation/animation_utils.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/product_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _selectedSize;
  String? _selectedColor;
  int _currentImageIndex = 0;

  // Complete The Look & Recommendations
  List<Product> _lookItems = [];
  List<Product> _recommendations = [];
  final Set<String> _selectedBundleIds = {};
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ProductService.getProductById(widget.productId);
      
      // Record in Recently Viewed
      await RecentlyViewedService.addViewedProduct(widget.productId);

      setState(() {
        _product = product;
        _loading = false;
        if (product.sizes.isNotEmpty) _selectedSize = product.sizes.first;
        if (product.colors.isNotEmpty) _selectedColor = product.colors.first;
        _selectedBundleIds.add(product.id);
      });

      // Fetch supplementary fashion data in background
      _loadSupplementaryData(product.id);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSupplementaryData(String productId) async {
    try {
      final look = await ProductService.getCompleteTheLook(productId);
      final recs = await ProductService.getRecommendations(productId);

      if (mounted) {
        setState(() {
          _lookItems = look;
          _recommendations = recs;
          for (final item in look) {
            _selectedBundleIds.add(item.id);
          }
        });
      }
    } catch (_) {
      // Ignore background recommendation errors gracefully
    }
  }

  void _addToCart() {
    if (_product == null) return;

    context.read<CartProvider>().addItem(
          _product!,
          size: _selectedSize,
          color: _selectedColor,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_product!.name} added to cart',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppTheme.accent,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _addBundleToCart() {
    if (_product == null) return;
    final bundle = <Product>[];
    if (_selectedBundleIds.contains(_product!.id)) {
      bundle.add(_product!);
    }
    for (final item in _lookItems) {
      if (_selectedBundleIds.contains(item.id)) {
        bundle.add(item);
      }
    }

    if (bundle.isEmpty) return;

    context.read<CartProvider>().addLookBundle(bundle);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added ${bundle.length} styled items to your cart!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppTheme.accent,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _showNotifyDialog(String notifyType) {
    _emailController.clear();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              notifyType == 'back_in_stock'
                  ? Icons.notifications_active_rounded
                  : Icons.local_offer_rounded,
              color: AppTheme.accent,
            ),
            const SizedBox(width: 10),
            Text(
              notifyType == 'back_in_stock'
                  ? 'Back in Stock Alert'
                  : 'Price Drop Alert',
              style: const TextStyle(fontFamily: 'Playfair', fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notifyType == 'back_in_stock'
                  ? 'Enter your email to get notified when ${_product?.name} is restocked.'
                  : 'Enter your email to receive an instant alert when price drops on ${_product?.name}.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              try {
                await ProductService.requestNotification(
                  _product!.id,
                  email,
                  notifyType,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primary,
                      content: Text('Alert preference saved! We will email $email.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to register notification. Please try again.')),
                  );
                }
              }
            },
            child: const Text('NOTIFY ME'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(flex: 3, child: ProductCardSkeleton()),
              SizedBox(height: 20),
              Expanded(flex: 2, child: ProductCardSkeleton()),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: CustomEmptyState(
          icon: Icons.search_off_rounded,
          title: "Product Not Found",
          description: "This attire piece might have been removed or is temporarily unavailable.",
          buttonText: "BACK TO SHOP",
          onButtonPressed: () => Navigator.pop(context),
        ),
      );
    }

    final p = _product!;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Calculate complete the look total price
    double bundleTotal = 0;
    if (_selectedBundleIds.contains(p.id)) bundleTotal += p.effectivePrice;
    for (final item in _lookItems) {
      if (_selectedBundleIds.contains(item.id)) bundleTotal += item.effectivePrice;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Image gallery app bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: isDesktop ? 480 : 380,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            actions: [
              // Price Drop Alert button
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary),
                tooltip: 'Set Price Alert',
                onPressed: () => _showNotifyDialog('price_drop'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Consumer<WishlistProvider>(
                  builder: (context, wishlist, _) {
                    final saved = wishlist.isWishlisted(p.id);
                    return PulseIconButton(
                      onTap: () async {
                        final ok = await context
                            .read<WishlistProvider>()
                            .toggle(p);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Sign in to save items to your wishlist',
                              ),
                              action: SnackBarAction(
                                label: 'SIGN IN',
                                textColor: AppTheme.accent,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                              ),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: saved ? AppTheme.primary : AppTheme.textDark,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: p.imageUrls.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: CachedNetworkImage(
                        key: ValueKey(p.imageUrls[index]),
                        imageUrl: p.imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            Container(color: const Color(0xFFF7F4EE)),
                      ),
                    ),
                  ),
                  // Image dots indicator
                  if (p.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          p.imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: i == _currentImageIndex ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i == _currentImageIndex
                                  ? AppTheme.primary
                                  : Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Product Info & Selection ──────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeInSlide(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & SKU
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.categoryDisplayName.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (p.sku != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            'SKU: ${p.sku}',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 28,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Price Section
                    if (p.isOnSale)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p.formattedEffectivePrice,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              p.formattedPrice,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textGrey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${p.discountPercent}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        p.formattedPrice,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Size selector
                    if (p.sizes.isNotEmpty) ...[
                      const Text(
                        'Select Size',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: p.sizes
                            .map(
                              (size) => GestureDetector(
                                onTap: () => setState(() => _selectedSize = size),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedSize == size
                                        ? AppTheme.primary
                                        : Colors.white,
                                    border: Border.all(
                                      color: _selectedSize == size
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    size,
                                    style: TextStyle(
                                      color: _selectedSize == size
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Color Explorer selector (Feature 2)
                    if (p.colors.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            'Color Explorer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedColor != null)
                            Text(
                              '— $_selectedColor',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: p.colors
                            .map(
                              (color) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                    // Crossfade image index if multi-color image exists
                                    final colorIndex = p.colors.indexOf(color);
                                    if (colorIndex < p.imageUrls.length) {
                                      _currentImageIndex = colorIndex;
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedColor == color
                                        ? AppTheme.accent.withValues(alpha: 0.12)
                                        : Colors.white,
                                    border: Border.all(
                                      color: _selectedColor == color
                                          ? AppTheme.accent
                                          : AppTheme.border,
                                      width: _selectedColor == color ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    color,
                                    style: TextStyle(
                                      color: _selectedColor == color
                                          ? AppTheme.textDark
                                          : AppTheme.textGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Description
                    const Text(
                      'Craftsmanship & Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Playfair',
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.description,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        height: 1.7,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Add to cart & Notify buttons
                    Row(
                      children: [
                        Expanded(
                          child: ScaleHoverCard(
                            child: ElevatedButton.icon(
                              onPressed: p.inStock ? _addToCart : () => _showNotifyDialog('back_in_stock'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.inStock ? AppTheme.primary : AppTheme.accent,
                                minimumSize: const Size(double.infinity, 54),
                                elevation: 3,
                                shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                              ),
                              icon: Icon(
                                p.inStock ? Icons.shopping_bag_outlined : Icons.notifications_active_outlined,
                                color: Colors.white,
                              ),
                              label: Text(
                                p.inStock ? 'ADD TO SHOPPING CART' : 'NOTIFY WHEN BACK IN STOCK',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // ── FEATURE 1: COMPLETE THE LOOK BUNDLE ────────────────
                    if (_lookItems.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'STYLED LOOK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Complete The Look',
                                  style: TextStyle(
                                    fontFamily: 'Playfair',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hand-crafted pairings styled by Noor’s master designers.',
                              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            // Bundle items check list
                            ...[p, ..._lookItems].map((item) {
                              final isSelected = _selectedBundleIds.contains(item.id);
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppTheme.primary,
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  item.formattedEffectivePrice,
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                secondary: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: item.primaryImage,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedBundleIds.add(item.id);
                                    } else {
                                      _selectedBundleIds.remove(item.id);
                                    }
                                  });
                                },
                              );
                            }),
                            const Divider(height: 24),

                            // Total & Add Bundle Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('BUNDLE TOTAL:', style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                                    Text(
                                      'PKR ${bundleTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _selectedBundleIds.isEmpty ? null : _addBundleToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.style_outlined, size: 18),
                                  label: Text('ADD ${_selectedBundleIds.length} ITEMS TO CART'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],

                    // ── FEATURE 8: SMART RECOMMENDATIONS ────────────────────
                    if (_recommendations.isNotEmpty) ...[
                      const Text(
                        'You May Also Like',
                        style: TextStyle(
                          fontFamily: 'Playfair',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 320,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendations.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final rec = _recommendations[index];
                            return SizedBox(
                              width: 200,
                              child: ProductCard(
                                product: rec,
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(productId: rec.id),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
