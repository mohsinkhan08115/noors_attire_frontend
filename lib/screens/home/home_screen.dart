import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/homepage_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/animation/animation_utils.dart';
import '../../services/api_service.dart';
import '../../models/homepage_config.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_overlay.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().loadHomeData();
      context.read<WishlistProvider>().load();
      context.read<HomepageProvider>().load();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final homepageConfig = context.watch<HomepageProvider>().config;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: isDesktop ? null : const _MobileDrawer(),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── SECTION 2 — PREMIUM NAVBAR ─────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: _isScrolled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            elevation: _isScrolled ? 2 : 0,
            shadowColor: Colors.black12,
            iconTheme: const IconThemeData(color: AppTheme.textDark),
            title: Text(
              AppConstants.appName,
              style: const TextStyle(
                fontFamily: 'Playfair',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.primary,
              ),
            ),
            centerTitle: !isDesktop,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textDark,
                ),
                tooltip: 'Search',
                onPressed: () => showSearchOverlay(context),
              ),
              Consumer<WishlistProvider>(
                builder: (context, wishlist, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: AppTheme.textDark,
                      ),
                      tooltip: 'Wishlist',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/wishlist'),
                    ),
                    if (wishlist.count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${wishlist.count}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppTheme.textDark,
                      ),
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
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
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
              IconButton(
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.textDark,
                ),
                tooltip: 'Account Profile',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],

        body: Builder(
          builder: (context) {
            final innerController =
                PrimaryScrollController.maybeOf(context) ?? _scrollController;
            return ScrollRevealScope(
              controller: innerController,
              child: SingleChildScrollView(
                controller: innerController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── SECTION 3 — HERO SECTION (admin-configurable) ──────────────
                    _HeroBanner(config: homepageConfig.hero),
                    const SizedBox(height: 48),

                    // ── SECTIONS 4–14 — admin-configurable order & visibility ──────
                    ..._buildDynamicSections(context, homepageConfig),

                    // ── RECENTLY VIEWED & COMMUNITY STYLED SECTIONS ───────────────
                    const ScrollReveal(child: _RecentlyViewedSection()),
                    const SizedBox(height: 56),
                    const ScrollReveal(child: _StyledCommunityGallery()),
                    const SizedBox(height: 56),

                    // ── SECTION 15 — PREMIUM FOOTER ────────────────────────────────
                    const ScrollReveal(yOffset: 20, child: _Footer()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the reorderable/toggleable middle section of the homepage from
  /// the admin-configured section list. Unknown keys are ignored so an old
  /// cached config never crashes the page.
  List<Widget> _buildDynamicSections(
    BuildContext context,
    HomepageConfig config,
  ) {
    final widgets = <Widget>[];
    final sections = config.orderedEnabledSections;
    for (int i = 0; i < sections.length; i++) {
      final section = _sectionWidget(context, sections[i].key);
      if (section == null) continue;
      widgets.add(section);
      widgets.add(SizedBox(height: _spacingAfter(sections[i].key)));
    }
    return widgets;
  }

  double _spacingAfter(String key) {
    switch (key) {
      case 'bestsellers':
      case 'editorial':
      case 'showcase':
      case 'social_gallery':
      case 'newsletter':
        return 64;
      default:
        return 56;
    }
  }

  Widget? _sectionWidget(BuildContext context, String key) {
    switch (key) {
      case 'categories':
        return Column(
          children: [
            const ScrollReveal(
              child: _SectionHeader(
                title: 'Shop by Category',
                subtitle: 'Explore our heritage craftsmanship',
              ),
            ),
            const SizedBox(height: 20),
            const ScrollReveal(
              delay: Duration(milliseconds: 80),
              child: _CategoriesRow(),
            ),
          ],
        );
      case 'featured':
        return Column(
          children: [
            const ScrollReveal(
              child: _SectionHeader(
                title: 'The Royal Collection',
                subtitle: 'Hand-picked regal attire designed for distinction',
              ),
            ),
            const SizedBox(height: 24),
            const ScrollReveal(
              delay: Duration(milliseconds: 80),
              child: _FeaturedCarousel(),
            ),
          ],
        );
      case 'new_arrivals':
        return Column(
          children: [
            const ScrollReveal(
              child: _SectionHeader(
                title: 'New Arrivals',
                subtitle: 'Freshly tailored seasonal releases',
              ),
            ),
            const SizedBox(height: 24),
            const _NewArrivalsGrid(),
          ],
        );
      case 'bestsellers':
        return Column(
          children: [
            const ScrollReveal(
              child: _SectionHeader(
                title: 'Bestsellers',
                subtitle: 'Timeless pieces loved most by our customers',
              ),
            ),
            const SizedBox(height: 20),
            const ScrollReveal(
              delay: Duration(milliseconds: 80),
              child: _BestsellersCarousel(),
            ),
          ],
        );
      case 'editorial':
        return const ScrollReveal(child: _EditorialFashionBanner());
      case 'showcase':
        return const ScrollReveal(child: _SignatureProductShowcase());
      case 'brand_story':
        return const ScrollReveal(child: _BrandStoryBlock());
      case 'trust_badges':
        return const ScrollReveal(child: _TrustBadgesRow());
      case 'testimonials':
        return const ScrollReveal(child: _TestimonialsSection());
      case 'social_gallery':
        return const ScrollReveal(child: _SocialGalleryGrid());
      case 'newsletter':
        return const ScrollReveal(child: _NewsletterSection());
      default:
        return null;
    }
  }
}

// ─── SECTION 1 — Announcement Bar (admin-configurable) ──────────────────────
class _AnnouncementBar extends StatelessWidget {
  final AnnouncementConfig config;

  const _AnnouncementBar({required this.config});

  Color get _background {
    switch (config.backgroundStyle) {
      case 'primary':
        return AppTheme.primary;
      case 'accent':
        return AppTheme.accent;
      default:
        return const Color(0xFF1A0A08);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!config.isActive || config.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final marqueeItems = [
      config.text,
      "✦ FREE EXPRESS SHIPPING ON ALL ORDERS OVER PKR 5,000",
      "✦ AUTHENTIC PASHTUN HERITAGE",
      "✦ CASH ON DELIVERY AVAILABLE",
      "✦ ISLAMABAD · BAHRIA TOWN · PHASE 8",
    ];

    final content = ColoredBox(
      color: _background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: MarqueeTicker(
          items: marqueeItems,
          textStyle: TextStyle(
            color: _background == AppTheme.accent
                ? AppTheme.textDark
                : AppTheme.accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );

    if (config.link == null || config.link!.isEmpty) return content;

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(config.link!)),
      child: content,
    );
  }
}

// ─── SECTION 2 — Custom Mobile Drawer Navigation ────────────────────────────
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            color: const Color(0xFF1A0A08),
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Noor's Attire",
                  style: TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Pashtun Heritage, Modern Style",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _drawerTile(context, Icons.home_outlined, 'Home', '/'),
                _drawerTile(
                  context,
                  Icons.storefront_outlined,
                  'Shop All Products',
                  '/products',
                ),
                _drawerTile(
                  context,
                  Icons.checkroom_outlined,
                  'Pashtun Dresses',
                  '/products',
                  arguments: AppConstants.categoryPashtunDress,
                ),
                _drawerTile(
                  context,
                  Icons.palette_outlined,
                  'Paint Shirts',
                  '/products',
                  arguments: AppConstants.categoryPaintShirt,
                ),
                _drawerTile(
                  context,
                  Icons.style_outlined,
                  'Build Your Own Look',
                  '/builder',
                ),
                _drawerTile(
                  context,
                  Icons.menu_book_outlined,
                  'Interactive Lookbook',
                  '/lookbook',
                ),
                _drawerTile(
                  context,
                  Icons.favorite_border_rounded,
                  'Wishlist',
                  '/wishlist',
                ),
                _drawerTile(
                  context,
                  Icons.shopping_bag_outlined,
                  'Shopping Cart',
                  '/cart',
                ),
                _drawerTile(
                  context,
                  Icons.person_outline_rounded,
                  'My Account',
                  '/profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    Object? arguments,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textDark,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route, arguments: arguments);
      },
    );
  }
}

// ─── SECTION 3 — Luxury Hero Banner (admin-configurable) ────────────────────
class _HeroBanner extends StatelessWidget {
  final HeroConfig config;

  const _HeroBanner({required this.config});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final hasImage = config.imageUrl != null && config.imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 520 : 620),
      color: const Color(0xFF1A0A08),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient image with slow zoom animation
          Positioned.fill(
            child: SlowZoomImage(
              child: CachedNetworkImage(
                imageUrl: hasImage
                    ? config.imageUrl!
                    : 'https://images.unsplash.com/photo-1597983073750-16f5ded1321f?w=1600&h=900&fit=crop&auto=format',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Dark gradient overlays matching Figma (#1a0a08/90 to transparent)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF1A0A08).withValues(alpha: 0.92),
                    const Color(0xFF1A0A08).withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [const Color(0xFF1A0A08), Colors.transparent],
                ),
              ),
            ),
          ),

          // Decorative pattern painter
          Positioned.fill(child: CustomPaint(painter: _LuxuryPatternPainter())),

          // Decorative floating glowing orbs (8s and 6s float loop matching Figma)
          Positioned(
            top: 20,
            right: 40,
            child: IgnorePointer(
              child: FloatingOrb(
                duration: const Duration(seconds: 8),
                floatDistance: 20,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 100,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 120,
            child: IgnorePointer(
              child: FloatingOrb(
                duration: const Duration(seconds: 6),
                floatDistance: 16,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.20),
                        blurRadius: 80,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Hero Text & Staggered Motion Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  // Main Headline ("Noor's Attire")
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    beginOffset: const Offset(0, 0.2),
                    child: Text(
                      config.headline,
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: isMobile ? 48 : 76,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subheadline / Story snippet
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 600),
                    beginOffset: const Offset(0, 0.2),
                    child: Text(
                      config.subheadline,
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 18,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.6,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Interactive CTA Buttons
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 800),
                    beginOffset: const Offset(0, 0.2),
                    child: Wrap(
                      alignment: isMobile
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      spacing: 16,
                      runSpacing: 14,
                      children: [
                        ScaleHoverCard(
                          scaleAmount: 1.05,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/products',
                            arguments: _categoryArgument(
                              config.primaryCtaCategory,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              config.primaryCtaLabel.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                        ScaleHoverCard(
                          scaleAmount: 1.05,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/products',
                            arguments: _categoryArgument(
                              config.secondaryCtaCategory,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: Colors.white54,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              config.secondaryCtaLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Staggered Stats Counters Row (500+ Products, 10K+ Happy Patrons, etc.)
                  const SizedBox(height: 48),
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(0, 0.2),
                    child: Container(
                      padding: const EdgeInsets.only(top: 24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white12, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: isMobile
                            ? MainAxisAlignment.spaceAround
                            : MainAxisAlignment.start,
                        children: [
                          _heroStatItem("500+", "PRODUCTS"),
                          SizedBox(width: isMobile ? 12 : 36),
                          _heroStatItem("10K+", "HAPPY PATRONS"),
                          SizedBox(width: isMobile ? 12 : 36),
                          _heroStatItem("15+", "YEARS HERITAGE"),
                          SizedBox(width: isMobile ? 12 : 36),
                          _heroStatItem("4.9★", "RATING"),
                        ],
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

  static Widget _heroStatItem(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  /// Maps a stored category key to the argument `/products` expects.
  /// "all" (or anything unrecognized) shows the unfiltered shop.
  String? _categoryArgument(String category) {
    switch (category) {
      case 'pashtun_dress':
        return AppConstants.categoryPashtunDress;
      case 'paint_shirt':
        return AppConstants.categoryPaintShirt;
      default:
        return null;
    }
  }
}

class _LuxuryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 90.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path();
        path.moveTo(x, y - 25);
        path.lineTo(x + 25, y);
        path.lineTo(x, y + 25);
        path.lineTo(x - 25, y);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Section Header Widget ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Optional callback for "Explore All". When null the button still renders but
  /// navigates to '/products' via the ambient [Navigator].
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed:
                onSeeAll ?? () => Navigator.pushNamed(context, '/products'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore All',
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
    );
  }
}

// ─── SECTION 4 — Shop By Category ────────────────────────────────────────────
class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CategoryCard(
            label: 'All Products',
            icon: '✨',
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          CategoryCard(
            label: 'Pashtun Dresses',
            icon: '👗',
            onTap: () => Navigator.pushNamed(
              context,
              '/products',
              arguments: AppConstants.categoryPashtunDress,
            ),
          ),
          CategoryCard(
            label: 'Paint Shirts',
            icon: '🎨',
            onTap: () => Navigator.pushNamed(
              context,
              '/products',
              arguments: AppConstants.categoryPaintShirt,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION 5 — Featured Collection Carousel ────────────────────────────────
class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().featured;
    final isLoading = context.watch<ProductProvider>().isLoading;

    if (isLoading && products.isEmpty) {
      return const SizedBox(height: 320, child: ProductCardSkeleton());
    }

    if (products.isEmpty) return const SizedBox.shrink();

    return CarouselSlider(
      options: CarouselOptions(
        height: 340,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        viewportFraction: 0.75,
      ),
      items: products
          .map(
            (product) => ProductCard(
              product: product,
              onTap: () => Navigator.pushNamed(
                context,
                '/product',
                arguments: product.id,
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── SECTION 6 — New Arrivals Grid ───────────────────────────────────────────
class _NewArrivalsGrid extends StatelessWidget {
  const _NewArrivalsGrid();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final isLoading = context.watch<ProductProvider>().isLoading;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isLoading && products.isEmpty) {
      return ProductGridSkeleton(
        count: isDesktop ? 4 : 2,
        crossAxisCount: isDesktop ? 4 : 2,
      );
    }

    final newItems = products.take(4).toList();
    if (newItems.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: newItems.length,
      itemBuilder: (context, index) => ScrollReveal(
        delay: Duration(milliseconds: 80 * index),
        child: ProductCard(
          product: newItems[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/product',
            arguments: newItems[index].id,
          ),
        ),
      ),
    );
  }
}

// ─── SECTION 7 — Bestsellers Horizontal Carousel ────────────────────────────
class _BestsellersCarousel extends StatelessWidget {
  const _BestsellersCarousel();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().bestsellers;
    final isLoading = context.watch<ProductProvider>().isLoading;

    if (isLoading && products.isEmpty) {
      return const SizedBox(height: 280, child: ProductCardSkeleton());
    }

    if (products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) => Container(
          width: 220,
          margin: const EdgeInsets.only(right: 14),
          child: ProductCard(
            product: products[index],
            onTap: () => Navigator.pushNamed(
              context,
              '/product',
              arguments: products[index].id,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION 8 — Editorial Fashion Banner ─────────────────────────────────────
class _EditorialFashionBanner extends StatelessWidget {
  const _EditorialFashionBanner();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 400,
      color: const Color(0xFF1A0A08),
      child: Stack(
        children: [
          Positioned.fill(
            child: SlowZoomImage(
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1614098097306-c67b8020c04e?w=1600&h=800&fit=crop&auto=format',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A0A08).withValues(alpha: 0.60),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 36,
                ),
                borderRadius: 24,
                baseColor: const Color(0xFF1A0A08),
                opacity: 0.35,
                blur: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "TIMELESS STYLE & HERITAGE",
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Authentic Pashtun\nKhamak Embroidery",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: isMobile ? 32 : 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ScaleHoverCard(
                      scaleAmount: 1.05,
                      onTap: () => Navigator.pushNamed(context, '/products'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "DISCOVER COLLECTION",
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
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

// ─── SECTION 9 — Product Showcase Module ─────────────────────────────────────
class _SignatureProductShowcase extends StatelessWidget {
  const _SignatureProductShowcase();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().featured;
    if (products.isEmpty) return const SizedBox.shrink();
    final signatureItem = products.first;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: signatureItem.primaryImage,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _showcaseDetails(context, signatureItem),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: signatureItem.primaryImage,
                      height: 380,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: _showcaseDetails(context, signatureItem),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _showcaseDetails(BuildContext context, dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "THE SIGNATURE SPOTLIGHT",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.name,
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textGrey,
            height: 1.6,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          item.formattedPrice,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        ScaleHoverCard(
          onTap: () =>
              Navigator.pushNamed(context, '/product', arguments: item.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "DISCOVER SIGNATURE PIECE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SECTION 10 — Brand Story Block ──────────────────────────────────────────
class _BrandStoryBlock extends StatelessWidget {
  const _BrandStoryBlock();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(36),
      borderRadius: 16,
      baseColor: const Color(0xFFFAF7F0),
      opacity: 0.7,
      blur: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "MORE THAN CLOTHING",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "A Legacy of Pashtun Heritage & Precision",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Playfair',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: const Text(
              "Every garment at Noor's Attire honors centuries of cultural handcraft. From authentic Perahan Tunban tailoring to contemporary hand-painted art shirts, we fuse ancient motifs with modern elegance.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION 11 — Trust & Brand Values ───────────────────────────────────────
class _TrustBadgesRow extends StatelessWidget {
  const _TrustBadgesRow();

  static const _badges = [
    (
      icon: Icons.local_shipping_outlined,
      title: 'Express Shipping',
      subtitle: 'Across Pakistan',
    ),
    (
      icon: Icons.payments_outlined,
      title: 'Cash on Delivery',
      subtitle: 'Secure Payment',
    ),
    (
      icon: Icons.verified_outlined,
      title: 'Authentic Fabrics',
      subtitle: '100% Quality Guaranteed',
    ),
    (
      icon: Icons.headset_mic_outlined,
      title: 'Dedicated Support',
      subtitle: 'Friendly Assistance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      borderRadius: 12,
      baseColor: Colors.white,
      opacity: 0.65,
      blur: 10,
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: _badges
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              b.icon,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                b.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          : Row(
              children: _badges
                  .map(
                    (b) => Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              b.icon,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  b.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  b.subtitle,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ─── SECTION 12 — Testimonials Section ───────────────────────────────────────
class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection> {
  int _activeIndex = 0;
  Timer? _timer;

  static const _reviews = [
    (
      name: 'Amina Khan',
      city: 'Peshawar',
      text:
          'The Khamak embroidery work on the Perahan Tunban is breathtaking. True heritage quality!',
      rating: 5,
    ),
    (
      name: 'Bilal Ahmad',
      city: 'Islamabad',
      text:
          'Order arrived in 2 days. The hand-painted shirt turns heads wherever I wear it.',
      rating: 5,
    ),
    (
      name: 'Zuhra Pashtun',
      city: 'Quetta',
      text:
          'Luxury fabric and perfect stitching. Feels like custom royal tailoring.',
      rating: 5,
    ),
    (
      name: 'Sara Yousafzai',
      city: 'Lahore',
      text:
          'I ordered the Chapan Coat as a gift — the recipient was in tears. Absolutely magnificent.',
      rating: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (mounted) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % _reviews.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = _reviews[_activeIndex];

    return Column(
      children: [
        const Text(
          "PATRON REVIEWS",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Words From Our Connoisseurs",
          style: TextStyle(
            fontFamily: 'Playfair',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 28),

        // Featured Spotlight Review Card
        Container(
          constraints: const BoxConstraints(maxWidth: 720),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Column(
              key: ValueKey(_activeIndex),
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    activeItem.rating,
                    (i) => const Icon(
                      Icons.star_rounded,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"${activeItem.text}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Playfair',
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  activeItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  '— ${activeItem.city}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_reviews.length, (index) {
            final isSelected = index == _activeIndex;
            return GestureDetector(
              onTap: () => setState(() => _activeIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isSelected ? 28 : 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Grid cards below
        Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _reviews.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              final isActive = idx == _activeIndex;

              return ScaleHoverCard(
                scaleAmount: 1.03,
                onTap: () => setState(() => _activeIndex = idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 240,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.border.withValues(alpha: 0.5),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          r.rating,
                          (i) => const Icon(
                            Icons.star_rounded,
                            color: AppTheme.accent,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"${r.text}"',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDark,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${r.name} — ${r.city}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── SECTION 13 — Social & Heritage Gallery Grid ────────────────────────────
class _SocialGalleryGrid extends StatelessWidget {
  const _SocialGalleryGrid();

  static const _images = [
    'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?auto=format&fit=crop&w=400&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "@NOORSATTIRE",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Follow The Heritage Journey",
            style: TextStyle(
              fontFamily: 'Playfair',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) => ScaleHoverCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: _images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION 14 — Newsletter Subscription ──────────────────────────────────
class _NewsletterSection extends StatefulWidget {
  const _NewsletterSection();

  @override
  State<_NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<_NewsletterSection> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.subscribeNewsletter(email);
      if (mounted) {
        _emailCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                SizedBox(width: 10),
                Text('Thank you for subscribing to Noor\'s Attire!'),
              ],
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      borderRadius: 16,
      baseColor: const Color(0xFF191919),
      opacity: 0.85,
      blur: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "JOIN THE NOOR'S ATTIRE WORLD",
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Receive Private Collection Releases & Heritage Insights",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Playfair',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter your email address...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleHoverCard(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      minimumSize: const Size(120, 52),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppTheme.textDark,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "SUBSCRIBE",
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RECENTLY VIEWED SECTION ─────────────────────────────────────────────────
class _RecentlyViewedSection extends StatefulWidget {
  const _RecentlyViewedSection();

  @override
  State<_RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<_RecentlyViewedSection> {
  List<Product> _recentProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final products = await RecentlyViewedService.getRecentlyViewed();
    if (mounted) {
      if (products.isNotEmpty) {
        setState(() => _recentProducts = products);
      } else {
        final allProds = context.read<ProductProvider>().products;
        if (allProds.isNotEmpty) {
          setState(() => _recentProducts = allProds.take(4).toList());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recentProducts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recently Viewed',
            subtitle: 'Pick up right where you left off',
            onSeeAll: () => Navigator.pushNamed(context, '/products'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = _recentProducts[index];
                return SizedBox(
                  width: 200,
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
          ),
        ],
      ),
    );
  }
}

// ─── STYLED BY COMMUNITY SECTION ─────────────────────────────────────────────
class _StyledCommunityGallery extends StatefulWidget {
  const _StyledCommunityGallery();

  @override
  State<_StyledCommunityGallery> createState() =>
      _StyledCommunityGalleryState();
}

class _StyledCommunityGalleryState extends State<_StyledCommunityGallery> {
  List<dynamic> _communityPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      final photos = await ProductService.getCommunityGallery();
      if (mounted) {
        setState(() {
          _communityPhotos = photos;
        });
      }
    } catch (_) {}
  }

  void _showSubmitModal() {
    final urlCtrl = TextEditingController();
    final handleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: AppTheme.accent),
            SizedBox(width: 10),
            Text(
              'Submit Your Look',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Showcase your Noor’s Attire style to our global fashion community!',
              style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: handleCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram / Social Handle',
                hintText: '@username',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Photo Image URL',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Outfit Caption',
                hintText: 'e.g. Royal Embroidered Velvet Frock at Eid',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (urlCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx);
              try {
                await ProductService.submitCommunityPhoto({
                  'image_url': urlCtrl.text.trim(),
                  'author_handle': handleCtrl.text.trim().isEmpty
                      ? '@anonymous'
                      : handleCtrl.text.trim(),
                  'caption': descCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.primary,
                      content: Text(
                        'Look submitted for curation approval! Thank you.',
                      ),
                    ),
                  );
                }
              } catch (_) {}
            },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final photos = _communityPhotos.isNotEmpty
        ? _communityPhotos
        : [
            {
              'image_url':
                  'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&auto=format&fit=crop&q=80',
              'author_handle': '@noor_style',
              'caption': 'Pashtun Velvet Dress',
            },
            {
              'image_url':
                  'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&auto=format&fit=crop&q=80',
              'author_handle': '@artisan_fashion',
              'caption': 'Hand-Painted Floral Shirt',
            },
            {
              'image_url':
                  'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&auto=format&fit=crop&q=80',
              'author_handle': '@royal_couture',
              'caption': 'Embroidered Silk Shawl',
            },
            {
              'image_url':
                  'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=600&auto=format&fit=crop&q=80',
              'author_handle': '@pakistan_fashion',
              'caption': 'Heritage Kurta Set',
            },
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#STYLED BY COMMUNITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppTheme.accent,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real People, Royal Heritage',
                    style: TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showSubmitModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  // The app's global ElevatedButtonTheme sets minimumSize to
                  // Size(double.infinity, 52) for full-width CTA buttons
                  // (Sign In, Add to Cart, etc). This button instead sits
                  // inline in a Row next to a heading, so it must override
                  // that to size itself to its content — otherwise it
                  // demands infinite width, which a Row cannot satisfy and
                  // throws during layout.
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text(
                  'SUBMIT LOOK',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.builder(
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final p = photos[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: p['image_url'] ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: const Color(0xFFF5F2EC)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['author_handle'] ?? '@fan',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            p['caption'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── SECTION 15 — Premium Footer ─────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0604),
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Column
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Noor's Attire",
                            style: TextStyle(
                              fontFamily: 'Playfair',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "AUTHENTIC PASHTUN CLOTHING",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Crafted with Heritage & Perfection — bringing the soul of Pashtun culture to every wardrobe.",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),

                    // Quick Links
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SHOP",
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _footerLink(context, 'All Products', '/products'),
                          _footerLink(
                            context,
                            'Pashtun Dresses',
                            '/products',
                            argument: AppConstants.categoryPashtunDress,
                          ),
                          _footerLink(
                            context,
                            'Paint Shirts',
                            '/products',
                            argument: AppConstants.categoryPaintShirt,
                          ),
                          _footerLink(context, 'Lookbook', '/lookbook'),
                          _footerLink(context, 'Outfit Builder', '/builder'),
                        ],
                      ),
                    ),

                    // Contact Column
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CONTACT US",
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _footerContactItem(
                            Icons.location_on_outlined,
                            "Location",
                            "Islamabad, Bahria Town, Phase 8",
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://maps.google.com/?q=Bahria+Town+Phase+8+Islamabad',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _footerContactItem(
                            Icons.phone_outlined,
                            "Phone / WhatsApp",
                            "+92 334 0588115",
                            onTap: () =>
                                launchUrl(Uri.parse('tel:+923340588115')),
                          ),
                          const SizedBox(height: 10),
                          _footerContactItem(
                            Icons.email_outlined,
                            "Email",
                            "noorattire247@gmail.com",
                            onTap: () => launchUrl(
                              Uri.parse('mailto:noorattire247@gmail.com'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Text(
                      "Noor's Attire",
                      style: TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Authentic Pashtun Clothing — Crafted with Heritage & Perfection",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _footerContactItem(
                      Icons.location_on_outlined,
                      "Location",
                      "Islamabad, Bahria Town, Phase 8",
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://maps.google.com/?q=Bahria+Town+Phase+8+Islamabad',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _footerContactItem(
                      Icons.phone_outlined,
                      "Phone / WhatsApp",
                      "+92 334 0588115",
                      onTap: () => launchUrl(Uri.parse('tel:+923340588115')),
                    ),
                    const SizedBox(height: 10),
                    _footerContactItem(
                      Icons.email_outlined,
                      "Email",
                      "noorattire247@gmail.com",
                      onTap: () => launchUrl(
                        Uri.parse('mailto:noorattire247@gmail.com'),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 24),

              Text(
                "© ${DateTime.now().year} Noor's Attire. All rights reserved. Crafted with care in Islamabad.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _footerLink(
    BuildContext context,
    String label,
    String route, {
    Object? argument,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route, arguments: argument),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  static Widget _footerContactItem(
    IconData icon,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
