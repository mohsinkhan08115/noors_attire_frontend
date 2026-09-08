// lib/screens/product/product_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/animation/animation_utils.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        context.read<ProductProvider>().setCategory(args);
      }
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Our Collection",
          style: TextStyle(
            fontFamily: 'Playfair',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search dresses, shirts, colors...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<ProductProvider>().search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (q) => context.read<ProductProvider>().search(q),
                ),
              ),
              // Category filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const _FilterChip(label: 'All Products', category: 'all'),
                    const SizedBox(width: 8),
                    const _FilterChip(
                      label: 'Pashtun Dresses',
                      category: AppConstants.categoryPashtunDress,
                    ),
                    const SizedBox(width: 8),
                    const _FilterChip(
                      label: 'Paint Shirts',
                      category: AppConstants.categoryPaintShirt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: _buildProductGrid(provider, isDesktop),
    );
  }

  Widget _buildProductGrid(ProductProvider provider, bool isDesktop) {
    if (provider.isLoading) {
      return ProductGridSkeleton(
        count: isDesktop ? 8 : 6,
        crossAxisCount: isDesktop ? 4 : 2,
      );
    }

    if (provider.error != null) {
      return CustomEmptyState(
        icon: Icons.error_outline_rounded,
        title: "Unable to Load Collection",
        description: provider.error!,
        buttonText: "RETRY",
        onButtonPressed: () => context.read<ProductProvider>().loadProducts(),
      );
    }

    final products = _searchCtrl.text.isNotEmpty
        ? provider.searchResults
        : provider.filteredProducts;

    if (products.isEmpty) {
      return CustomEmptyState(
        icon: Icons.search_off_rounded,
        title: "No Products Found",
        description: "Try clearing search keywords or selecting another category.",
        buttonText: "RESET FILTERS",
        onButtonPressed: () {
          _searchCtrl.clear();
          context.read<ProductProvider>().setCategory('all');
          context.read<ProductProvider>().search('');
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => FadeInSlide(
        delay: Duration(milliseconds: 50 * (index % 6)),
        child: ProductCard(
          product: products[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/product',
            arguments: products[index].id,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String category;

  const _FilterChip({required this.label, required this.category});

  @override
  Widget build(BuildContext context) {
    final isSelected =
        context.watch<ProductProvider>().selectedCategory == category;
    return GestureDetector(
      onTap: () => context.read<ProductProvider>().setCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
