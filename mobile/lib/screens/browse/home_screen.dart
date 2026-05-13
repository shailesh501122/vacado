import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import '../../widgets/product_card.dart';
import '../account/address_screen.dart';
import '../product/product_details_screen.dart';
import 'listing_screen.dart';
import 'search_screen.dart';

/// Blinkit / Zepto inspired home — colourful gradient header, dense
/// promotional sections, category pills, all dynamically driven by the
/// catalog API.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Gradient colours for the header — bright mint→teal like the reference.
  static const _headerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFA8E6CF), Color(0xFF7BD3B5), Color(0xFF4FB89A)],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadHome();
      context.read<AddressProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final user = context.watch<AuthProvider>().user;
    final defaultAddr = context.watch<AddressProvider>().defaultAddress;
    final eta = _eta(catalog);

    return RefreshIndicator(
      color: VTokens.green,
      onRefresh: () => catalog.loadHome(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(eta, defaultAddr, user?.avatarInitial ?? 'V')),
          SliverToBoxAdapter(child: const SizedBox(height: 18)),
          if (catalog.banners.isNotEmpty)
            SliverToBoxAdapter(child: _heroBanner(catalog)),
          if (catalog.categories.isNotEmpty)
            SliverToBoxAdapter(child: _categoryGrid(catalog)),
          if (catalog.bestsellers.isNotEmpty)
            SliverToBoxAdapter(child: _section('Best sellers today', catalog.bestsellers)),
          SliverToBoxAdapter(child: _flashStrip()),
          if (catalog.trending.isNotEmpty)
            SliverToBoxAdapter(child: _gridSection('Trending now', catalog.trending)),
          if (catalog.recommended.isNotEmpty)
            SliverToBoxAdapter(child: _gridSection('Recommended for you', catalog.recommended)),
          SliverToBoxAdapter(
            child: SizedBox(height: VBottomNav.heightFor(context) + 16),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────
  Widget _header(int etaMin, dynamic addr, String initial) {
    final addressLine = addr == null
      ? 'Set delivery location'
      : '${addr.tag} — ${addr.city}';
    final subtitleLine = addr == null
      ? 'Tap to add an address'
      : addr.fullLine;

    return Container(
      decoration: const BoxDecoration(gradient: _headerGradient),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressScreen())),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.flash_on_rounded, size: 24, color: VTokens.ink),
                        const SizedBox(width: 4),
                        Text('$etaMin mins',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: VTokens.ink)),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: VTokens.ink),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(addressLine,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VTokens.ink)),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: VTokens.ink),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(left: 22, top: 1),
                        child: Text(subtitleLine,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: VTokens.ink2, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () { /* profile tab on bottom nav */ },
                child: Container(
                  width: 40, height: 40, alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: const Icon(Icons.person_outline_rounded, color: VTokens.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: 20, color: VTokens.ink3),
                const SizedBox(width: 10),
                const Expanded(child: Text("Search 'mango', 'milk', 'bread'…",
                  style: TextStyle(color: VTokens.ink3, fontSize: 14))),
                const Icon(Icons.mic_none_rounded, size: 20, color: VTokens.green700),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  int _eta(CatalogProvider c) {
    // Use the fastest ETA from any in-stock product as a real signal.
    final all = [...c.bestsellers, ...c.trending, ...c.recommended];
    if (all.isEmpty) return 12;
    return all.map((p) => p.etaMinutes).reduce((a, b) => a < b ? a : b);
  }

  // ─── Hero banner ───────────────────────────────────────
  Widget _heroBanner(CatalogProvider c) {
    final b = c.banners.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 158,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
              child: Transform.rotate(angle: .26, child: FruitTile(kind: b.fruitKind, size: 140, radius: 28, blobScale: .8)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (b.tag != null) VBadge(label: b.tag!, tone: 'dark'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: Text(b.title, style: AppTheme.serif(size: 26, letterSpacing: -.4)),
                    ),
                  ],
                ),
                if (b.subtitle != null)
                  Text(b.subtitle!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VTokens.ink2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Categories ────────────────────────────────────────
  Widget _categoryGrid(CatalogProvider c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Shop by category'),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: c.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: .8,
            ),
            itemBuilder: (_, i) {
              final cat = c.categories[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingScreen(category: cat.slug, title: cat.name))),
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FruitTile(kind: cat.fruitKind, radius: 18, blobScale: .66),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VTokens.ink2), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Horizontal product strip ──────────────────────────
  Widget _section(String title, List<Product> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(title: title, link: 'See all'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 152,
                child: ProductCard(
                  product: list[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: list[i].slug))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grid product section ──────────────────────────────
  Widget _gridSection(String title, List<Product> list) {
    final n = list.length > 6 ? 6 : list.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, link: 'See all'),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: n,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .66,
            ),
            itemBuilder: (_, i) => ProductCard(
              product: list[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: list[i].slug))),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Flash deals strip ─────────────────────────────────
  Widget _flashStrip() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
    child: Container(
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
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flash deals · live now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VTokens.ink)),
              SizedBox(height: 1),
              Text('Up to 60% off — refreshed every hour', style: TextStyle(fontSize: 11, color: VTokens.ink2, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: VTokens.ink2),
      ]),
    ),
  );
}
