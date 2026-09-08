import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium Glassmorphism + Liquid Glass card component.
/// Combines subtle backdrop blur, semi-transparent layers,
/// soft rounded borders, and gentle refraction highlights.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final Color baseColor;
  final VoidCallback? onTap;
  final BoxBorder? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.blur = 12.0,
    this.opacity = 0.5,
    this.baseColor = Colors.white,
    this.onTap,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = baseColor.computeLuminance() < 0.5;
    final highlightColor = Colors.white;
    final shadowColor = isDark ? Colors.black : Colors.black;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: opacity),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  highlightColor.withValues(alpha: isDark ? opacity * 0.4 : opacity * 0.8),
                  baseColor.withValues(alpha: opacity),
                  highlightColor.withValues(alpha: isDark ? opacity * 0.1 : opacity * 0.4),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: customBorder ?? Border.all(
                color: highlightColor.withValues(alpha: isDark ? 0.15 : 0.4),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  left: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          highlightColor.withValues(alpha: isDark ? 0.08 : 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }
    return card;
  }
}
