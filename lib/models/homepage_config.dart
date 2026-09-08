// lib/models/homepage_config.dart
//
// Mirrors GET /homepage. Every field has a sensible default matching
// what the homepage looked like before it became admin-editable, so a
// failed/slow fetch never leaves the page broken or blank.

class AnnouncementConfig {
  final bool isActive;
  final String text;
  final String? link;
  final String backgroundStyle;

  const AnnouncementConfig({
    required this.isActive,
    required this.text,
    this.link,
    required this.backgroundStyle,
  });

  factory AnnouncementConfig.fromJson(Map<String, dynamic> json) {
    return AnnouncementConfig(
      isActive: json['is_active'] ?? false,
      text: json['text'] ?? '',
      link: json['link'],
      backgroundStyle: json['background_style'] ?? 'dark',
    );
  }

  static const fallback = AnnouncementConfig(
    isActive: true,
    text: "✨ FREE EXPRESS SHIPPING ON ALL ORDERS OVER PKR 5,000 | "
        "AUTHENTIC PASHTUN HERITAGE",
    backgroundStyle: 'dark',
  );
}

class HeroConfig {
  final String badgeText;
  final String headline;
  final String subheadline;
  final String? imageUrl;
  final String primaryCtaLabel;
  final String primaryCtaCategory;
  final String secondaryCtaLabel;
  final String secondaryCtaCategory;

  const HeroConfig({
    required this.badgeText,
    required this.headline,
    required this.subheadline,
    this.imageUrl,
    required this.primaryCtaLabel,
    required this.primaryCtaCategory,
    required this.secondaryCtaLabel,
    required this.secondaryCtaCategory,
  });

  factory HeroConfig.fromJson(Map<String, dynamic> json) {
    return HeroConfig(
      badgeText: json['badge_text'] ?? fallback.badgeText,
      headline: json['headline'] ?? fallback.headline,
      subheadline: json['subheadline'] ?? fallback.subheadline,
      imageUrl: json['image_url'],
      primaryCtaLabel: json['primary_cta_label'] ?? fallback.primaryCtaLabel,
      primaryCtaCategory:
          json['primary_cta_category'] ?? fallback.primaryCtaCategory,
      secondaryCtaLabel:
          json['secondary_cta_label'] ?? fallback.secondaryCtaLabel,
      secondaryCtaCategory:
          json['secondary_cta_category'] ?? fallback.secondaryCtaCategory,
    );
  }

  static const fallback = HeroConfig(
    badgeText: 'ROYAL HERITAGE COLLECTION 2026',
    headline: "Noor's Attire",
    subheadline: 'Elegance in Every Thread — Authentic Pashtun Craftsmanship',
    primaryCtaLabel: 'EXPLORE DRESSES',
    primaryCtaCategory: 'pashtun_dress',
    secondaryCtaLabel: 'PAINT SHIRTS',
    secondaryCtaCategory: 'paint_shirt',
  );
}

class HomepageSectionConfig {
  final String key;
  final bool enabled;
  final int order;

  const HomepageSectionConfig({
    required this.key,
    required this.enabled,
    required this.order,
  });

  factory HomepageSectionConfig.fromJson(Map<String, dynamic> json) {
    return HomepageSectionConfig(
      key: json['key'] ?? '',
      enabled: json['enabled'] ?? true,
      order: json['order'] ?? 0,
    );
  }
}

const List<String> defaultHomepageSectionKeys = [
  'categories',
  'featured',
  'new_arrivals',
  'bestsellers',
  'editorial',
  'showcase',
  'brand_story',
  'trust_badges',
  'testimonials',
  'social_gallery',
  'newsletter',
];

class HomepageConfig {
  final AnnouncementConfig announcement;
  final HeroConfig hero;
  final List<HomepageSectionConfig> sections;

  const HomepageConfig({
    required this.announcement,
    required this.hero,
    required this.sections,
  });

  factory HomepageConfig.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List?;
    return HomepageConfig(
      announcement: json['announcement'] != null
          ? AnnouncementConfig.fromJson(json['announcement'])
          : AnnouncementConfig.fallback,
      hero: json['hero'] != null
          ? HeroConfig.fromJson(json['hero'])
          : HeroConfig.fallback,
      sections: sectionsJson != null && sectionsJson.isNotEmpty
          ? sectionsJson.map((s) => HomepageSectionConfig.fromJson(s)).toList()
          : fallbackSections,
    );
  }

  static List<HomepageSectionConfig> get fallbackSections => [
    for (int i = 0; i < defaultHomepageSectionKeys.length; i++)
      HomepageSectionConfig(
        key: defaultHomepageSectionKeys[i],
        enabled: true,
        order: i,
      ),
  ];

  static HomepageConfig fallback = HomepageConfig(
    announcement: AnnouncementConfig.fallback,
    hero: HeroConfig.fallback,
    sections: fallbackSections,
  );

  /// Enabled sections, sorted by their configured order.
  List<HomepageSectionConfig> get orderedEnabledSections {
    final enabled = sections.where((s) => s.enabled).toList();
    enabled.sort((a, b) => a.order.compareTo(b.order));
    return enabled;
  }
}
