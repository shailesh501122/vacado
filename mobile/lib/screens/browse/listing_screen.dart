import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/primitives.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
import 'search_screen.dart';

class ListingScreen extends StatefulWidget {
  final String? category;
  final String title;
  const ListingScreen({super.key, this.category, required this.title});
  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  bool _loading = true;
  List<Product> _items = [];
  String _sort = 'popular';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await context.read<CatalogProvider>().listFor(category: widget.category, sort: _sort);
    if (!mounted) return;
    setState(() {
      _items = items; _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: VTokens.green))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
                    itemCount: _items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .66,
                    ),
                    itemBuilder: (_, i) => ProductCard(
                      product: _items[i],
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: _items[i].slug))),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          VBackButton(onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTheme.serif(size: 22, letterSpacing: -.3, color: VTokens.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${_items.length} items · delivers in 10 min', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                ),
              ],
            ),
          ),
          IconBox(icon: Icons.search_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()))),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            VChip(label: 'Filters · 2', icon: Icons.tune_rounded, active: true),
            const SizedBox(width: 6),
            VChip(label: 'Organic only', dot: VTokens.green),
            const SizedBox(width: 6),
            const VChip(label: 'Under ₹100'),
            const SizedBox(width: 6),
            const VChip(label: 'Imported'),
            const SizedBox(width: 6),
            const VChip(label: 'Local farms'),
          ]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(TextSpan(
              text: 'Showing ',
              style: const TextStyle(fontSize: 12, color: VTokens.ink3),
              children: [
                TextSpan(text: '1 – ${_items.length}', style: const TextStyle(color: VTokens.ink, fontWeight: FontWeight.w800)),
                TextSpan(text: ' of ${_items.length}'),
              ],
            )),
            PopupMenuButton<String>(
              initialValue: _sort,
              onSelected: (v) { _sort = v; _load(); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'popular',    child: Text('Most popular')),
                PopupMenuItem(value: 'price_asc',  child: Text('Price · low to high')),
                PopupMenuItem(value: 'price_desc', child: Text('Price · high to low')),
                PopupMenuItem(value: 'rating',     child: Text('Rating')),
              ],
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sort: Most popular', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VTokens.ink2)),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: VTokens.ink2),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
