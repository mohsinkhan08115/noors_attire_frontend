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
  final Product? initialProduct;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _selectedSize;
  String? _selectedColor;
  int _currentImageIndex = 0;
  int _quantity = 1;

  // Complete The Look & Recommendations
  List<Product> _lookItems = [];
  List<Product> _recommendations = [];
  final Set<String> _selectedBundleIds = {};
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
      _loading = false;
      if (_product!.sizes.isNotEmpty) _selectedSize = _product!.sizes.first;
      if (_product!.colors.isNotEmpty) _selectedColor = _product!.colors.first;
      _selectedBundleIds.add(_product!.id);
      RecentlyViewedService.addViewedProduct(_product!.id);
      _loadSupplementaryData(_product!.id);
    } else {
      _loadProduct();
    }
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

      if (mounted) {
        setState(() {
          _product = product;
          _loading = false;
          if (product.sizes.isNotEmpty) _selectedSize = product.sizes.first;
          if (product.colors.isNotEmpty) _selectedColor = product.colors.first;
          _selectedBundleIds.add(product.id);
        });

        // Fetch supplementary fashion data in background
        _loadSupplementaryData(product.id);
      }
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

    for (int i = 0; i < _quantity; i++) {
      context.read<CartProvider>().addItem(
            _product!,
            size: _selectedSize,
            color: _selectedColor,
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_quantity > 1 ? '$_quantity items of ' : ''}${_product!.name} added to cart',
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
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Padding(
          padding: EdgeInsets.all(24),
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Product Detail')),
        body: CustomEmptyState(
          icon: Icons.search_off_rounded,
          title: "Product Not Found",
          description: "This attire piece might have been removed or is temporarily unavailable.",
          buttonText: "BACK TO SHOP",
          onButtonPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/products');
            }
          },
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: Text(
          p.categoryDisplayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        centerTitle: !isDesktop,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary),
            tooltip: 'Set Price Alert',
            onPressed: () => _showNotifyDialog('price_drop'),
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              final saved = wishlist.isWishlisted(p.id);
              return IconButton(
                icon: Icon(
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: saved ? AppTheme.primary : AppTheme.textDark,
                ),
                tooltip: 'Wishlist',
                onPressed: () async {
                  final ok = await context.read<WishlistProvider>().toggle(p);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sign in to save items to your wishlist'),
                        action: SnackBarAction(
                          label: 'SIGN IN',
                          textColor: AppTheme.accent,
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textDark),
                  tooltip: 'Cart',
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── DESKTOP: LEFT IMAGE / RIGHT INFO ──────────────────────────
                // ── MOBILE: STACKED VERTICALLY ────────────────────────────────
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Product Image & Gallery
                      Expanded(
                        flex: 5,
                        child: _buildImageGallery(p, isDesktop),
                      ),
                      const SizedBox(width: 48),
                      // RIGHT COLUMN: Product Information & Controls
                      Expanded(
                        flex: 5,
                        child: _buildProductInfo(p, isDesktop),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageGallery(p, isDesktop),
                      const SizedBox(height: 28),
                      _buildProductInfo(p, isDesktop),
                    ],
                  ),

                const SizedBox(height: 64),

                // ── COMPLETE THE LOOK BUNDLE ──────────────────────────────────
                if (_lookItems.isNotEmpty) ...[
                  _buildCompleteTheLook(p, bundleTotal),
                  const SizedBox(height: 64),
                ],

                // ── RELATED PRODUCTS / YOU MAY ALSO LIKE ──────────────────────
                if (_recommendations.isNotEmpty) ...[
                  _buildRelatedProducts(isDesktop),
                  const SizedBox(height: 48),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── LEFT: IMAGE GALLERY WIDGET ──────────────────────────────────────────────
  Widget _buildImageGallery(Product p, bool isDesktop) {
    final images = p.imageUrls.isNotEmpty ? p.imageUrls : [p.primaryImage];
    final activeIndex = _currentImageIndex.clamp(0, images.length - 1);
    final activeImageUrl = images[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Large Image
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: isDesktop ? 0.95 : 1.05,
                  child: CachedNetworkImage(
                    key: ValueKey(activeImageUrl),
                    imageUrl: activeImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF7F4EE),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF7F4EE),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textGrey,
                        size: 48,
                      ),
                    ),
                  ),
                ),

                // Sale Badge on Image
                if (p.isOnSale)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${p.discountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Featured / Bestseller Badge
                if (p.isBestseller)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: AppTheme.accent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'BESTSELLER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Gallery Thumbnails (if multiple images exist)
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = index == activeIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFFF7F4EE)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── RIGHT: PRODUCT INFO & CONTROLS WIDGET ───────────────────────────────────
  Widget _buildProductInfo(Product p, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge & SKU
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            if (p.sku != null && p.sku!.isNotEmpty) ...[
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
        const SizedBox(height: 14),

        // Product Name
        Text(
          p.name,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: isDesktop ? 32 : 26,
            height: 1.25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Price Section
        if (p.isOnSale)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                p.formattedEffectivePrice,
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: TextStyle(
              fontSize: isDesktop ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),

        const SizedBox(height: 14),

        // Availability / Stock Status Indicator
        Row(
          children: [
            Icon(
              p.inStock ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
              size: 16,
              color: p.inStock ? const Color(0xFF2E7D32) : AppTheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              p.inStock
                  ? (p.stock > 0 ? 'In Stock (${p.stock} available)' : 'In Stock')
                  : 'Temporarily Out of Stock',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.inStock ? const Color(0xFF2E7D32) : AppTheme.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 20),

        // Size Selector
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
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSize == size ? AppTheme.primary : Colors.white,
                        border: Border.all(
                          color: _selectedSize == size ? AppTheme.primary : AppTheme.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        size,
                        style: TextStyle(
                          color: _selectedSize == size ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
        ],

        // Color Explorer Selector
        if (p.colors.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Color Selection',
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
                          color: _selectedColor == color ? AppTheme.accent : AppTheme.border,
                          width: _selectedColor == color ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        color,
                        style: TextStyle(
                          color: _selectedColor == color ? AppTheme.textDark : AppTheme.textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
        ],

        // Quantity Selector
        Row(
          children: [
            const Text(
              'Quantity:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    splashRadius: 18,
                    tooltip: 'Decrease quantity',
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 32),
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => setState(() => _quantity++),
                    splashRadius: 18,
                    tooltip: 'Increase quantity',
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Action Buttons: Add to Cart & Wishlist
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            const SizedBox(width: 12),
            Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                final saved = wishlist.isWishlisted(p.id);
                return OutlinedButton(
                  onPressed: () => wishlist.toggle(p),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(54, 54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(
                      color: saved ? AppTheme.primary : AppTheme.border,
                      width: 1.5,
                    ),
                    backgroundColor: saved ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
                  ),
                  child: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: saved ? AppTheme.primary : AppTheme.textDark,
                    size: 22,
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Craftsmanship & Details Description
        const Text(
          'Craftsmanship & Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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

        const SizedBox(height: 28),

        // Assurance / Brand Trust Reassurance
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppTheme.accent, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '100% Authentic Heritage Craftsmanship | Direct from Noor’s Master Artisans',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── COMPLETE THE LOOK BUNDLE ────────────────────────────────────────────────
  Widget _buildCompleteTheLook(Product p, double bundleTotal) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const SizedBox(width: 12),
              const Text(
                'Complete The Look',
                style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 22,
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
          const SizedBox(height: 20),

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
                  width: 54,
                  height: 54,
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
          const Divider(height: 28),

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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.style_outlined, size: 18),
                label: Text('ADD ${_selectedBundleIds.length} ITEMS TO CART'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── RELATED PRODUCTS / YOU MAY ALSO LIKE ──────────────────────────────────
  Widget _buildRelatedProducts(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You May Also Like',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Curated pieces relevant to your signature selection',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/products',
                arguments: _product?.category,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Collection',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grid on desktop (4 items per row), smooth horizontal scroll on mobile
        if (isDesktop)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return ProductCard(
                product: rec,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: rec.id,
                      initialProduct: rec,
                    ),
                  ),
                ),
              );
            },
          )
        else
          SizedBox(
            height: 350,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final rec = _recommendations[index];
                return SizedBox(
                  width: 220,
                  child: ProductCard(
                    product: rec,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: rec.id,
                          initialProduct: rec,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
