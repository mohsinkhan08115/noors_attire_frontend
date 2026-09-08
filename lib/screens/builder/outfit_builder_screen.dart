// lib/screens/builder/outfit_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animation/animation_utils.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/constants/app_constants.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  int _currentStep = 0;
  Product? _selectedOutfit;
  Product? _selectedLayer;
  Product? _selectedAccessory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().loadProducts();
    });
  }

  double get _totalPrice {
    double sum = 0.0;
    if (_selectedOutfit != null) sum += _selectedOutfit!.effectivePrice;
    if (_selectedLayer != null) sum += _selectedLayer!.effectivePrice;
    if (_selectedAccessory != null) sum += _selectedAccessory!.effectivePrice;
    return sum;
  }

  void _addEntireLookToCart() {
    final bundle = <Product>[];
    if (_selectedOutfit != null) bundle.add(_selectedOutfit!);
    if (_selectedLayer != null) bundle.add(_selectedLayer!);
    if (_selectedAccessory != null) bundle.add(_selectedAccessory!);

    if (bundle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one item for your look.")),
      );
      return;
    }

    context.read<CartProvider>().addLookBundle(bundle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
            const SizedBox(width: 10),
            Text('Complete look (${bundle.length} items) added to cart! 🎉'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppTheme.accent,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Build Your Own Look",
          style: TextStyle(
            fontFamily: 'Playfair',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _stepIndicator(0, "1. Outfit"),
                _stepDivider(),
                _stepIndicator(1, "2. Layer"),
                _stepDivider(),
                _stepIndicator(2, "3. Accessory"),
                _stepDivider(),
                _stepIndicator(3, "4. Review"),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(products),
            ),
          ),

          // Total & Checkout Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Look Total",
                        style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                      ),
                      Text(
                        'PKR ${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ScaleHoverCard(
                      child: ElevatedButton(
                        onPressed: _addEntireLookToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "ADD ENTIRE LOOK TO CART",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return GestureDetector(
      onTap: () => setState(() => _currentStep = step),
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive
                ? AppTheme.primary
                : (isDone ? AppTheme.accent : AppTheme.border),
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: (isActive || isDone) ? Colors.white : AppTheme.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.primary : AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        color: AppTheme.border,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildStepContent(List<Product> products) {
    if (_currentStep == 3) {
      return _buildReviewStep();
    }

    final categoryFilter = _currentStep == 0
        ? AppConstants.categoryPashtunDress
        : AppConstants.categoryPaintShirt;

    final filtered = products.where((p) => p.category == categoryFilter).toList();
    final items = filtered.isNotEmpty ? filtered : products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentStep == 0
              ? "Select Main Pashtun Outfit"
              : (_currentStep == 1
                  ? "Select Matching Layer / Shirt"
                  : "Select Matching Accessories"),
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            final isSelected = (_currentStep == 0 && _selectedOutfit?.id == p.id) ||
                (_currentStep == 1 && _selectedLayer?.id == p.id) ||
                (_currentStep == 2 && _selectedAccessory?.id == p.id);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_currentStep == 0) _selectedOutfit = p;
                  if (_currentStep == 1) _selectedLayer = p;
                  if (_currentStep == 2) _selectedAccessory = p;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: CachedNetworkImage(
                          imageUrl: p.primaryImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            p.formattedPrice,
                            style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final bundle = [_selectedOutfit, _selectedLayer, _selectedAccessory]
        .whereType<Product>()
        .toList();

    if (bundle.isEmpty) {
      return const Center(
        child: Text("No items selected. Return to step 1 to choose outfit items."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Your Customized Look",
          style: TextStyle(fontFamily: 'Playfair', fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...bundle.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: p.primaryImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(p.formattedPrice, style: const TextStyle(color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
