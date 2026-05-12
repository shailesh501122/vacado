class Product {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String fruitKind;
  final String? origin;
  final String weightLabel;
  final int pricePaise;
  final int? mrpPaise;
  final int discountPercent;
  final double rating;
  final int reviewCount;
  final int etaMinutes;
  final bool isOrganic;
  final bool isTrending;
  final bool isBestseller;
  final int stock;
  final Map<String, dynamic> nutrition;
  final List<dynamic> packOptions;

  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.fruitKind,
    required this.weightLabel,
    required this.pricePaise,
    this.mrpPaise,
    this.discountPercent = 0,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.etaMinutes = 10,
    this.isOrganic = false,
    this.isTrending = false,
    this.isBestseller = false,
    this.stock = 100,
    this.description,
    this.origin,
    this.nutrition = const {},
    this.packOptions = const [],
  });

  int get priceRupees => (pricePaise / 100).round();
  int? get mrpRupees  => mrpPaise == null ? null : (mrpPaise! / 100).round();

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    fruitKind: (j['fruitKind'] as String?) ?? 'apple',
    origin: j['origin'] as String?,
    weightLabel: (j['weightLabel'] as String?) ?? '500 g',
    pricePaise: (j['pricePaise'] as num).toInt(),
    mrpPaise: j['mrpPaise'] == null ? null : (j['mrpPaise'] as num).toInt(),
    discountPercent: (j['discountPercent'] as num?)?.toInt() ?? 0,
    rating: (j['rating'] as num?)?.toDouble() ?? 4.5,
    reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    etaMinutes: (j['etaMinutes'] as num?)?.toInt() ?? 10,
    isOrganic: (j['isOrganic'] as bool?) ?? false,
    isTrending: (j['isTrending'] as bool?) ?? false,
    isBestseller: (j['isBestseller'] as bool?) ?? false,
    stock: (j['stock'] as num?)?.toInt() ?? 100,
    nutrition: (j['nutrition'] as Map<String, dynamic>?) ?? const {},
    packOptions: (j['packOptions'] as List?) ?? const [],
  );
}

class Category {
  final String id;
  final String slug;
  final String name;
  final String fruitKind;
  final int position;

  Category({required this.id, required this.slug, required this.name, required this.fruitKind, required this.position});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    fruitKind: (j['fruitKind'] as String?) ?? 'apple',
    position: (j['position'] as num?)?.toInt() ?? 0,
  );
}

class Banner {
  final String title;
  final String? subtitle;
  final String? tag;
  final String fruitKind;
  final String? gradient;
  final String? ctaLabel;
  final String? ctaTarget;

  Banner({required this.title, this.subtitle, this.tag, required this.fruitKind, this.gradient, this.ctaLabel, this.ctaTarget});

  factory Banner.fromJson(Map<String, dynamic> j) => Banner(
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    tag: j['tag'] as String?,
    fruitKind: (j['fruitKind'] as String?) ?? 'mango',
    gradient: j['gradient'] as String?,
    ctaLabel: j['ctaLabel'] as String?,
    ctaTarget: j['ctaTarget'] as String?,
  );
}

class Coupon {
  final String id;
  final String code;
  final String title;
  final String? subtitle;
  final String tone;
  final String discountType;
  final int discountValue;
  final int minOrderPaise;

  Coupon({
    required this.id,
    required this.code,
    required this.title,
    this.subtitle,
    required this.tone,
    required this.discountType,
    required this.discountValue,
    this.minOrderPaise = 0,
  });

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
    id: j['id'] as String,
    code: j['code'] as String,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    tone: (j['tone'] as String?) ?? 'green',
    discountType: j['discountType'] as String,
    discountValue: (j['discountValue'] as num).toInt(),
    minOrderPaise: (j['minOrderPaise'] as num?)?.toInt() ?? 0,
  );
}
