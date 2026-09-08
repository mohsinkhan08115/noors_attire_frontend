// lib/core/animation/ambient_background.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// LuxuryAnimatedBackground provides a subtle, high-performance ambient
/// background system featuring slowly floating blurred gradient orbs,
/// champagne gold particles, and soft light shimmers.
///
/// Designed specifically for Noor's Attire:
/// - 100% Non-interactive (wrapped in [IgnorePointer] so it never blocks UI elements)
/// - Repaint isolated (wrapped in [RepaintBoundary] for 60 FPS Flutter Web rendering)
/// - Respects reduced-motion accessibility settings and mobile constraints
class LuxuryAnimatedBackground extends StatefulWidget {
  final Widget child;

  const LuxuryAnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<LuxuryAnimatedBackground> createState() =>
      _LuxuryAnimatedBackgroundState();
}

class _LuxuryAnimatedBackgroundState extends State<LuxuryAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _orbController1;
  late AnimationController _orbController2;

  @override
  void initState() {
    super.initState();

    // Orb 1: 18-second slow desynchronized cycle
    _orbController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    // Orb 2: 26-second slow desynchronized cycle
    _orbController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController1.dispose();
    _orbController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Base Warm Ivory Surface Layer ─────────────────────────────────
        const Positioned.fill(
          child: ColoredBox(color: AppTheme.background),
        ),

        // ── Ambient Animated Background Canvas ────────────────────────────
        // Wrapped in IgnorePointer so background CANNOT intercept touches/clicks
        // Wrapped in RepaintBoundary to isolate background repaints from content
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _orbController1,
                  _orbController2,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _LuxuryBackgroundPainter(
                      orbProgress1: disableAnimations ? 0.5 : _orbController1.value,
                      orbProgress2: disableAnimations ? 0.3 : _orbController2.value,
                      isMobile: isMobile,
                      disableAnimations: disableAnimations,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Main Page / Route Content ──────────────────────────────────────
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

/// CustomPainter for rendering GPU-accelerated gradient orbs & floating gold dust
class _LuxuryBackgroundPainter extends CustomPainter {
  final double orbProgress1;
  final double orbProgress2;
  final bool isMobile;
  final bool disableAnimations;

  _LuxuryBackgroundPainter({
    required this.orbProgress1,
    required this.orbProgress2,
    required this.isMobile,
    required this.disableAnimations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: on Flutter Web's first frame the canvas can be zero-sized
    // before the browser viewport is resolved. Canvas operations on a
    // zero-size surface trigger validators.dart:36:10 assertions.
    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;

    final width = size.width;
    final height = size.height;

    // ── 1. Soft Luxury Burgundy Gradient Orb ──────────────────────────────
    // Moves along a slow Lissajous curve in top-right quadrant
    final orb1Radius = isMobile ? width * 0.45 : width * 0.32;
    final orb1Angle = orbProgress1 * 2 * math.pi;
    final orb1X = width * 0.75 + math.sin(orb1Angle) * (width * 0.12);
    final orb1Y = height * 0.20 + math.cos(orb1Angle * 0.7) * (height * 0.08);

    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withValues(alpha: isMobile ? 0.04 : 0.06),
          AppTheme.primary.withValues(alpha: 0.015),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: orb1Radius),
      );

    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, orb1Paint);

    // ── 2. Soft Luxury Saffron Gold Gradient Orb ──────────────────────────
    // Moves along a slow Lissajous curve in mid-left quadrant
    final orb2Radius = isMobile ? width * 0.50 : width * 0.36;
    final orb2Angle = orbProgress2 * 2 * math.pi;
    final orb2X = width * 0.20 + math.cos(orb2Angle * 0.8) * (width * 0.14);
    final orb2Y = height * 0.55 + math.sin(orb2Angle * 0.5) * (height * 0.12);

    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withValues(alpha: isMobile ? 0.04 : 0.07),
          AppTheme.accent.withValues(alpha: 0.018),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: orb2Radius),
      );

    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, orb2Paint);

    // ── 3. Subtle Hero Ambient Top Shimmer Glow ───────────────────────────
    final shimmerRadius = width * 0.60;
    final shimmerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFDF8).withValues(alpha: 0.70),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(width * 0.5, 0), radius: shimmerRadius),
      );

    canvas.drawCircle(Offset(width * 0.5, 0), shimmerRadius, shimmerPaint);


  }

  @override
  bool shouldRepaint(covariant _LuxuryBackgroundPainter oldDelegate) {
    return oldDelegate.orbProgress1 != orbProgress1 ||
        oldDelegate.orbProgress2 != orbProgress2 ||
        oldDelegate.isMobile != isMobile ||
        oldDelegate.disableAnimations != disableAnimations;
  }
}
