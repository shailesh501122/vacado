import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/fruit_tile.dart';
import '../product/product_details_screen.dart';
import 'listing_screen.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _activeIndex = 0;
  List<Product> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFor(0));
  }

  Future<void> _loadFor(int idx) async {
    final cats = context.read<CatalogProvider>().categories;
    if (cats.isEmpty) {
      await context.read<CatalogProvider>().loadHome();
    }
    final categories = context.read<CatalogProvider>().categories;
    if (categories.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final cat = categories[idx];
    setState(() => _loading = true);
    final items = await context.read<CatalogProvider>().listFor(category: cat.slug);
    if (!mounted) return;
    setState(() {
      _activeIndex = idx;
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogProvider>().categories;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _leftRail(categories),
                Expanded(child: _rightGrid(categories)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VTokens.line)),
            child: const Icon(Icons.menu_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Browse', style: AppTheme.serif(size: 28, letterSpacing: -.4)),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VTokens.line)),
            child: Row(children: const [
              Icon(Icons.search_rounded, size: 16, color: VTokens.ink3),
              SizedBox(width: 8),
              Text('Find fruits, vegetables, juices…', style: TextStyle(color: VTokens.ink3, fontSize: 13)),
            ]),
          ),
        ),
      ],
    ),
  );

  Widget _leftRail(List cats) {
    return Container(
      width: 88, padding: const EdgeInsets.only(top: 12, bottom: 180),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: VTokens.line2))),
      child: ListView.builder(
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final active = i == _activeIndex;
          final cat = cats[i];
          return GestureDetector(
            onTap: () => _loadFor(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              color: active ? VTokens.bg : Colors.transparent,
              child: Stack(children: [
                if (active)
                  Positioned(left: -6, top: 14, bottom: 14, child: Container(width: 3, decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(99)))),
                Column(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: active ? VTokens.green25 : VTokens.line2, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: FruitTile(kind: cat.fruitKind, size: 40, radius: 10, blobScale: .72)),
                  ),
                  const SizedBox(height: 6),
                  Text(cat.name, style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? VTokens.green700 : VTokens.ink2,
                  ), textAlign: TextAlign.center),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _rightGrid(List cats) {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: CircularProgressIndicator(color: VTokens.green)));
    if (cats.isEmpty || _items.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: Text('Nothing to show')));
    }
    final activeCat = cats[_activeIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activeCat.name.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .82,
              ),
              itemBuilder: (_, i) {
                final p = _items[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: p.slug))),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.line2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(aspectRatio: 1.2, child: FruitTile(kind: p.fruitKind, radius: 10, blobScale: .62)),
                        const SizedBox(height: 8),
                        Text(p.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('₹${p.priceRupees} · ${p.weightLabel}', style: const TextStyle(fontSize: 10.5, color: VTokens.ink3)),
                      ],
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
