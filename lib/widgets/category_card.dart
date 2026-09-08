import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/animation/animation_utils.dart';
import 'glass_card.dart';

class CategoryCard extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleHoverCard(
      scaleAmount: 1.05,
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(right: 14),
        borderRadius: 16,
        baseColor: Colors.white,
        opacity: 0.65,
        blur: 10,
        child: SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
