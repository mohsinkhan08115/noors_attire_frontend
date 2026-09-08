// lib/screens/wishlist/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animation/animation_utils.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TextEditingController _collectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<WishlistProvider>().load();
    });
  }

  @override
  void dispose() {
    _collectionController.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog(BuildContext context) {
    _collectionController.clear();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: AppTheme.accent),
            SizedBox(width: 10),
            Text(
              'New Collection',
              style: TextStyle(fontFamily: 'Playfair', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organize your favorite outfits into customized occasion boards (e.g., Eid 2026, Barat Wear, Summer Lawn).',
              style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _collectionController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Eid 2026',
              ),
              autofocus: true,
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
              final name = _collectionController.text.trim();
              if (name.isNotEmpty) {
                await context.read<WishlistProvider>().createCollection(name);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primary,
                      content: Text('Collection "$name" created!'),
                    ),
                  );
                }
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Smart Wishlist & Collections',
          style: TextStyle(
            fontFamily: 'Playfair',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppTheme.primary),
            tooltip: 'Create New Collection',
            onPressed: () => _showCreateCollectionDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collection Tabs Header
          if (!wishlist.requiresLogin && !wishlist.isLoading) ...[
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _collectionChip(context, wishlist, "All"),
                  ...wishlist.collections.keys.map((c) => _collectionChip(context, wishlist, c)),
                  GestureDetector(
                    onTap: () => _showCreateCollectionDialog(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accent, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 16, color: AppTheme.accent),
                          SizedBox(width: 4),
                          Text(
                            'NEW BOARD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          Expanded(
            child: _body(wishlist, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _collectionChip(BuildContext context, WishlistProvider wishlist, String name) {
    final isSelected = wishlist.selectedCollection == name;
    return GestureDetector(
      onTap: () => wishlist.setCollection(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF5F2EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(WishlistProvider wishlist, bool isDesktop) {
    if (wishlist.requiresLogin) {
      return CustomEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Sign In to View Wishlist',
        description: 'Save your favourite Pashtun dresses and artisan shirts to review anytime.',
        buttonText: 'SIGN IN',
        onButtonPressed: () => Navigator.pushNamed(context, '/login'),
      );
    }

    if (wishlist.isLoading) {
      return ProductGridSkeleton(
        count: isDesktop ? 4 : 2,
        crossAxisCount: isDesktop ? 4 : 2,
      );
    }

    final displayItems = wishlist.filteredCollectionItems;

    if (displayItems.isEmpty) {
      return CustomEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No Items in "${wishlist.selectedCollection}"',
        description: 'Tap the heart icon on any dress or shirt to add it to your saved items.',
        buttonText: 'EXPLORE CATALOG',
        onButtonPressed: () => Navigator.pushNamed(context, '/products'),
      );
    }

    return RefreshIndicator(
      onRefresh: wishlist.load,
      color: AppTheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final product = displayItems[index];
          return FadeInSlide(
            delay: Duration(milliseconds: 50 * index),
            child: ProductCard(
              product: product,
              onTap: () => Navigator.pushNamed(
                context,
                '/product',
                arguments: product.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
