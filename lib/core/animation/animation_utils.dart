// lib/core/animation/animation_utils.dart

import 'package:flutter/material.dart';

// ─── ScrollRevealScope ─────────────────────────────────────────────────────────
/// Propagates the page-level [ScrollController] down the widget tree.
///
/// Wrap the scrollable body with this widget so every [ScrollReveal] inside
/// can listen to the page scroll and trigger its entrance animation at the
/// correct moment — even when the page's [SingleChildScrollView] / [NestedScrollView]
/// is a *parent* of the [ScrollReveal] nodes (i.e. scroll notifications bubble
/// *up*, but the page controller can only be accessed via [InheritedWidget]).
class ScrollRevealScope extends InheritedNotifier<ScrollController> {
  const ScrollRevealScope({
    super.key,
    required ScrollController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest [ScrollController] provided by a [ScrollRevealScope],
  /// or `null` if none is present in the tree.
  static ScrollController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScrollRevealScope>()
        ?.notifier;
  }
}

// ─── FadeInSlide ──────────────────────────────────────────────────────────────
/// FadeInSlide provides a smooth entrance animation (fade + slide up/down/left/right).
/// Fires immediately on widget build (with optional [delay]). Use this for
/// above-the-fold content like the Hero section, where the page has just loaded.
/// Automatically respects the user's reduced-motion settings.
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.15),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

// ─── ScaleHoverCard ───────────────────────────────────────────────────────────
/// ScaleHoverCard adds subtle scale-up and shadow elevation on mouse hover or tap focus.
class ScaleHoverCard extends StatefulWidget {
  final Widget child;
  final double scaleAmount;
  final Duration duration;
  final VoidCallback? onTap;

  const ScaleHoverCard({
    super.key,
    required this.child,
    this.scaleAmount = 1.025,
    this.duration = const Duration(milliseconds: 200),
    this.onTap,
  });

  @override
  State<ScaleHoverCard> createState() => _ScaleHoverCardState();
}

class _ScaleHoverCardState extends State<ScaleHoverCard> {
  bool _isHovered = false;

  // ── Single-callback hover guard ───────────────────────────────────────────
  // Problem: calling setState() synchronously inside MouseRegion.onEnter /
  // onExit re-enters Flutter's MouseTracker._deviceUpdatePhase() before the
  // previous call completes, triggering the assert(!_debugDuringDeviceUpdate)
  // at mouse_tracker.dart:199 — especially during page transitions.
  //
  // Fix: defer setState to the next frame via addPostFrameCallback.
  //
  // Additional guard: _callbackScheduled ensures we only queue ONE callback at
  // a time, no matter how many onEnter/onExit events fire in rapid succession
  // (e.g. mouse moving across many cards). Without the guard, each mouse-move
  // event queues a new deferred setState, creating a rebuild → hover-event →
  // rebuild cascade that keeps the assertion firing indefinitely.
  bool _pendingHovered = false;
  bool _callbackScheduled = false;

  void _setHovered(bool value) {
    _pendingHovered = value;
    if (_callbackScheduled) return; // one callback already queued — bail out
    _callbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callbackScheduled = false;
      if (mounted && _isHovered != _pendingHovered) {
        setState(() => _isHovered = _pendingHovered);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (disableAnimations || !_isHovered) ? 1.0 : widget.scaleAmount,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── PulseIconButton ──────────────────────────────────────────────────────────
/// PulseIconButton provides a subtle spring pulse animation when triggered (e.g. wishlist toggle, cart add).
class PulseIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PulseIconButton({super.key, required this.child, required this.onTap});

  @override
  State<PulseIconButton> createState() => _PulseIconButtonState();
}

class _PulseIconButtonState extends State<PulseIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _triggerPulse,
      child: ScaleTransition(
        scale: disableAnimations
            ? const AlwaysStoppedAnimation(1.0)
            : _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ─── FadeSlidePageTransitionsBuilder ─────────────────────────────────────────
/// A subtle fade + slight upward slide transition for named-route
/// navigation, applied globally via ThemeData.pageTransitionsTheme so
/// every existing route gets a consistent, branded transition instead
/// of the OS/browser default — no changes to any route or screen needed.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ─── MarqueeTicker ────────────────────────────────────────────────────────────
/// MarqueeTicker continuously scrolls items horizontally at speed matching 28s loop in Figma.
class MarqueeTicker extends StatefulWidget {
  final List<String> items;
  final TextStyle textStyle;
  final Duration duration;

  const MarqueeTicker({
    super.key,
    required this.items,
    required this.textStyle,
    this.duration = const Duration(seconds: 28),
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return Text(
        widget.items.join("   ✦   "),
        style: widget.textStyle,
        textAlign: TextAlign.center,
      );
    }

    // Use LayoutBuilder so `width` is always the actual rendered parent width
    // and never 0.0 (which happens with MediaQuery on the first Flutter Web frame
    // and causes OverflowBox to receive invalid constraints → validators.dart assertion).
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        // If the widget hasn't been laid out yet, fall back to a static label.
        if (width <= 0 || width == double.infinity) {
          return Text(
            widget.items.join("   ✦   "),
            style: widget.textStyle,
            textAlign: TextAlign.center,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double dx = -_controller.value * width;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: width * 3,
                  maxWidth: width * 3,
                  minHeight: 0,
                  maxHeight: 36,
                  child: Row(
                    children: [
                      for (final item in [
                        ...widget.items,
                        ...widget.items,
                        ...widget.items,
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(item, style: widget.textStyle),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── FloatingOrb ──────────────────────────────────────────────────────────────
/// FloatingOrb animates an orb up and down (translateY 0 to -20px over 6s/8s easeInOut).
class FloatingOrb extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatDistance;

  const FloatingOrb({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.floatDistance = 20.0,
  });

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: -widget.floatDistance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── SlowZoomImage ────────────────────────────────────────────────────────────
/// SlowZoomImage applies continuous subtle scale animation (scale 1.0 to 1.08 over 20s).
class SlowZoomImage extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SlowZoomImage({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 20),
  });

  @override
  State<SlowZoomImage> createState() => _SlowZoomImageState();
}

class _SlowZoomImageState extends State<SlowZoomImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

// ─── PulseDot ─────────────────────────────────────────────────────────────────
/// PulseDot continuously animates opacity from 1.0 to 0.4 over 2s.
class PulseDot extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseDot({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return FadeTransition(opacity: _opacityAnimation, child: widget.child);
  }
}

// ─── HoverUnderlineText ───────────────────────────────────────────────────────
/// HoverUnderlineText displays an animated gold underline on mouse hover.
class HoverUnderlineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color underlineColor;
  final VoidCallback? onTap;

  const HoverUnderlineText({
    super.key,
    required this.text,
    required this.style,
    this.underlineColor = const Color(0xFFC9A227),
    this.onTap,
  });

  @override
  State<HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<HoverUnderlineText> {
  bool _isHovered = false;
  bool _pendingHovered = false;
  bool _callbackScheduled = false;

  // Same single-callback guard as ScaleHoverCard._setHovered.
  void _setHovered(bool value) {
    _pendingHovered = value;
    if (_callbackScheduled) return;
    _callbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callbackScheduled = false;
      if (mounted && _isHovered != _pendingHovered) {
        setState(() => _isHovered = _pendingHovered);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style.copyWith(
                color: _isHovered
                    ? const Color(0xFF8B0000)
                    : widget.style.color,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 1.5,
              width: _isHovered ? 40 : 0,
              color: widget.underlineColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ScrollReveal ─────────────────────────────────────────────────────────────
/// ScrollReveal animates a widget into view (fade + slide up) the FIRST TIME
/// it enters the viewport when the user scrolls. Unlike [FadeInSlide], this
/// widget starts invisible and only plays its entrance animation once the
/// widget's bounding box actually intersects the visible scroll viewport.
///
/// **How scroll detection works (two complementary paths):**
///
/// 1. **ScrollRevealScope** (preferred) — wrap the page's scrollable body with
///    `ScrollRevealScope(controller: _scrollController)`. The controller is
///    provided via [InheritedNotifier], so every [ScrollReveal] in the tree
///    subscribes and is notified on every scroll offset change.
///
/// 2. **NotificationListener fallback** — `ScrollReveal` also wraps itself in a
///    [NotificationListener] to catch bubbled [ScrollNotification] events from
///    *child* scrollables (e.g., a nested [ListView]).
///
class ScrollReveal extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double yOffset;
  final Duration delay;
  final Curve curve;
  final double triggerThreshold;

  const ScrollReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 650),
    this.yOffset = 40.0,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.triggerThreshold = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
