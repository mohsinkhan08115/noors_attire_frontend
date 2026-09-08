// lib/screens/lookbook/lookbook_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animation/animation_utils.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

class LookbookItem {
  final String title;
  final String imageUrl;
  final List<LookbookHotspot> hotspots;

  const LookbookItem({
    required this.title,
    required this.imageUrl,
    required this.hotspots,
  });
}

class LookbookHotspot {
  final String label;
  final String productId;
  final Offset position; // normalized 0.0 to 1.0

  const LookbookHotspot({
    required this.label,
    required this.productId,
    required this.position,
  });
}

class LookbookScreen extends StatefulWidget {
  const LookbookScreen({super.key});

  @override
  State<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends State<LookbookScreen> {
  static const List<LookbookItem> _lookbooks = [
    LookbookItem(
      title: "Royal Peshawari Heritage Look",
      imageUrl: "https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=1000&q=80",
      hotspots: [
        LookbookHotspot(label: "Perahan Dress", productId: "p1", position: Offset(0.48, 0.45)),
        LookbookHotspot(label: "Embroidered Silk Shawl", productId: "p2", position: Offset(0.68, 0.35)),
      ],
    ),
    LookbookItem(
      title: "Modern Artisan Paint Shirt Ensemble",
      imageUrl: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1000&q=80",
      hotspots: [
        LookbookHotspot(label: "Floral Paint Shirt", productId: "p3", position: Offset(0.50, 0.40)),
        LookbookHotspot(label: "Tribal Accent Band", productId: "p4", position: Offset(0.35, 0.65)),
      ],
    ),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final look = _lookbooks[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Interactive Lookbook",
          style: TextStyle(
            fontFamily: 'Playfair',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page Selector Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Tap golden pins to explore & shop outfit items",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey),
                    ),
                  ),
                  DropdownButton<int>(
                    value: _currentIndex,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) => setState(() => _currentIndex = v ?? 0),
                    items: List.generate(
                      _lookbooks.length,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text("Look ${i + 1}"),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Interactive Lookbook Image Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: look.imageUrl,
                        fit: BoxFit.cover,
                      ),

                      // Hotspots Overlays
                      ...look.hotspots.map((hs) {
                        return Positioned(
                          left: hs.position.dx * 320,
                          top: hs.position.dy * 400,
                          child: _HotspotPin(
                            label: hs.label,
                            onTap: () => _openProductPreview(hs.productId),
                          ),
                        );
                      }),

                      // Title overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            look.title,
                            style: const TextStyle(
                              fontFamily: 'Playfair',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _openProductPreview(String productId) {
    final prods = context.read<ProductProvider>().products;
    final prod = prods.firstWhere(
      (p) => p.id == productId,
      orElse: () => prods.isNotEmpty ? prods.first : throw Exception('No products'),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: prod.primaryImage,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prod.formattedPrice,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/product', arguments: prod.id);
                    },
                    child: const Text("VIEW PRODUCT"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(prod);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${prod.name} added to cart!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text("ADD TO CART"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HotspotPin extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HotspotPin({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PulseIconButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.lens,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}
