import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
import '../browse/listing_screen.dart';
import '../browse/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: VTokens.green,
        onRefresh: () => catalog.loadHome(),
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 120),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _topBar(user?.avatarInitial ?? 'V'),
            _searchBar(),
            const SizedBox(height: 8),
            _heroBanner(catalog),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(title: 'Shop by category', link: 'See all', onTap: () {}),
            ),
            const SizedBox(height: 12),
            _categoryGrid(catalog),
            const SizedBox(height: 22),
            _aiPick(catalog),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SectionHeader(title: 'Best sellers today', subtitle: 'From Karnataka farms', link: 'See all'),
            ),
            const SizedBox(height: 10),
            _horizontalProducts(catalog.bestsellers),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _flashStrip(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const SectionHeader(title: 'Trending in Bangalore'),
            ),
            const SizedBox(height: 12),
            _gridProducts(catalog.trending),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const SectionHeader(title: 'Recommended for you', subtitle: 'Based on what you love'),
            ),
            const SizedBox(height: 12),
            _gridProducts(catalog.recommended),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _topBar(String initial) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('DELIVERY IN 9 MIN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700, letterSpacing: .5)),
                SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: VTokens.ink3),
              ]),
              const SizedBox(height: 2),
              Row(children: const [
                Icon(Icons.location_on_outlined, size: 16, color: VTokens.ink),
                SizedBox(width: 4),
                Text('Indiranagar, BLR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VTokens.ink)),
              ]),
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 1),
                child: Text('4th Cross · Stage II', style: TextStyle(fontSize: 11, color: VTokens.ink3)),
              ),
            ],
          ),
        ),
        Row(children: [
          IconBox(icon: Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFE4E1), Color(0xFFFFD9DD)]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(initial.toUpperCase(),
              style: const TextStyle(color: VTokens.rose700, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ]),
      ],
    ),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
    child: GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: VTokens.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VTokens.line),
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, size: 18, color: VTokens.ink3),
          const SizedBox(width: 10),
          const Expanded(child: Text.rich(
            TextSpan(
              text: 'Search ',
              style: TextStyle(fontSize: 13.5, color: VTokens.ink3),
              children: [
                TextSpan(text: '"Alphonso mango"', style: TextStyle(color: VTokens.ink, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          Container(width: 1, height: 18, color: VTokens.line),
          const SizedBox(width: 10),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(99)),
            child: const Icon(Icons.mic_none_rounded, size: 16, color: VTokens.green700),
          ),
        ]),
      ),
    ),
  );

  Widget _heroBanner(CatalogProvider c) {
    final banner = c.banners.isNotEmpty ? c.banners.first : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 152,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFFE0CC), Color(0xFFFFD0A8), Color(0xFFFFC089)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -10, top: -10,
              child: Transform.rotate(angle: .26, child: FruitTile(kind: banner?.fruitKind ?? 'mango', size: 140, radius: 28, blobScale: .8)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VBadge(label: banner?.tag ?? 'SEASONAL', tone: 'dark'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: Text(banner?.title ?? 'Alphonso\nis here',
                        style: AppTheme.serif(size: 26, letterSpacing: -.4)),
                    ),
                  ],
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: const Text('FLAT 30% OFF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VTokens.ink)),
                  ),
                  const SizedBox(width: 8),
                  Text(banner?.subtitle ?? 'ends in 2h 14m',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VTokens.ink2)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid(CatalogProvider c) {
    if (c.categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: c.categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: .82,
        ),
        itemBuilder: (_, i) {
          final cat = c.categories[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingScreen(category: cat.slug, title: cat.name))),
            child: Column(
              children: [
                FruitTile(kind: cat.fruitKind, size: 70, radius: 18, blobScale: .66),
                const SizedBox(height: 6),
                Text(cat.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: VTokens.ink2), textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _aiPick(CatalogProvider c) {
    final pick = c.aiPick;
    final items = (pick['items'] as List?)?.cast<String>() ?? ['pomegranate', 'spinach', 'strawberry', 'almond'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [VTokens.green900, VTokens.green700]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 14),
              SizedBox(width: 8),
              Text('AI · PICKED FOR YOU', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: .5)),
            ]),
            const SizedBox(height: 6),
            Text(pick['title']?.toString() ?? 'Boost your morning iron',
              style: AppTheme.serif(size: 22, color: Colors.white, letterSpacing: -.3)),
            const SizedBox(height: 4),
            Text(pick['subtitle']?.toString() ?? 'Based on your last 12 orders + iron-rich profile',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.7))),
            const SizedBox(height: 12),
            Row(children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 0),
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : -8),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: VTokens.green700, width: 2)),
                    child: ClipOval(child: FruitTile(kind: items[i], size: 36, radius: 99, blobScale: .74)),
                  ),
                ),
              const SizedBox(width: 8),
              Text('+ ${pick['extraCount'] ?? 6} items', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: const Text('Try basket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VTokens.green700)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _flashStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFCD34D)),
      gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)]),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: VTokens.orange, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flash deals · ends in 1:42:08', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VTokens.ink)),
            SizedBox(height: 1),
            Text('Up to 60% off · 24 items live', style: TextStyle(fontSize: 11, color: VTokens.ink2, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const Icon(Icons.chevron_right_rounded, color: VTokens.ink2),
    ]),
  );

  Widget _horizontalProducts(List<Product> list) {
    if (list.isEmpty) return const SizedBox(height: 0);
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(
          width: 150,
          child: ProductCard(
            product: list[i],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: list[i].slug))),
          ),
        ),
      ),
    );
  }

  Widget _gridProducts(List<Product> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: list.length > 4 ? 4 : list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .68,
        ),
        itemBuilder: (_, i) => ProductCard(
          product: list[i],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: list[i].slug))),
        ),
      ),
    );
  }
}
