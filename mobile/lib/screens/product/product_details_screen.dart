import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import '../commerce/checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String slug;
  const ProductDetailsScreen({super.key, required this.slug});
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _p;
  int _packIdx = 0;
  bool _wished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<CatalogRepository>();
      final p = await repo.product(widget.slug);
      if (!mounted) return;
      final defaultIdx = p.packOptions.indexWhere((e) => (e as Map)['best'] == true);
      setState(() {
        _p = p;
        _packIdx = defaultIdx >= 0 ? defaultIdx : 0;
      });
    });
  }

  Future<void> _toggleWishlist() async {
    if (_p == null) return;
    final repo = context.read<WishlistRepository>();
    final saved = await repo.toggle(_p!.id);
    setState(() => _wished = saved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved ? 'Saved to wishlist' : 'Removed from wishlist'),
      ));
    }
  }

  Future<void> _addToCart() async {
    if (_p == null) return;
    await context.read<CartProvider>().add(_p!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_p!.name} added to cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) {
      return const Scaffold(backgroundColor: VTokens.bg, body: Center(child: CircularProgressIndicator(color: VTokens.green)));
    }

    final qty = context.select<CartProvider, int>((c) => c.qtyOf(p.id));

    return Scaffold(
      backgroundColor: VTokens.bg,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _gallery(p),
              Transform.translate(
                offset: const Offset(0, -16),
                child: Container(
                  decoration: const BoxDecoration(
                    color: VTokens.bg,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headline(p),
                      const SizedBox(height: 14),
                      _metaRow(p),
                      const SizedBox(height: 22),
                      _packs(p),
                      const SizedBox(height: 22),
                      _nutrition(p),
                      const SizedBox(height: 22),
                      _about(p),
                      const SizedBox(height: 22),
                      _reviews(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _floatingIcon(Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
                Row(children: [
                  _floatingIcon(_wished ? Icons.favorite : Icons.favorite_border, onTap: _toggleWishlist,
                    iconColor: _wished ? VTokens.rose600 : VTokens.ink),
                  const SizedBox(width: 8),
                  _floatingIcon(Icons.share_outlined),
                ]),
              ],
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.96),
                border: const Border(top: BorderSide(color: VTokens.line2)),
              ),
              child: Row(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.weightLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: VTokens.ink3)),
                    Text('₹${p.priceRupees}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: VTokens.ink)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: qty > 0
                    ? PrimaryBtn(
                        label: 'View in cart · $qty items',
                        icon: Icons.shopping_bag_outlined, fullWidth: true,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen())),
                      )
                    : PrimaryBtn(
                        label: 'Add to cart · ${p.etaMinutes} min',
                        icon: Icons.shopping_bag_outlined, fullWidth: true,
                        onPressed: _addToCart,
                      ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingIcon(IconData icon, {VoidCallback? onTap, Color? iconColor}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        shape: BoxShape.circle,
        boxShadow: VTokens.shadow1,
      ),
      child: Icon(icon, size: 18, color: iconColor ?? VTokens.ink),
    ),
  );

  Widget _gallery(Product p) => Container(
    height: 380,
    decoration: const BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE0CC), Color(0xFFFFD0A8)]),
    ),
    child: Stack(
      children: [
        Center(child: FruitTile(kind: p.fruitKind, size: 260, radius: 140, blobScale: .88)),
        Positioned(
          top: 110, left: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(99),
              boxShadow: VTokens.shadow1,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.eco_outlined, size: 14, color: VTokens.green700),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('FRESHNESS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .3)),
                  Text('Picked 8 hrs ago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: VTokens.green700, height: 1)),
                ],
              ),
            ]),
          ),
        ),
        Positioned(
          top: 110, right: 18,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: VTokens.shadow1),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: VTokens.green700, width: 1.5, style: BorderStyle.solid),
              ),
              alignment: Alignment.center,
              child: const Text('USDA\nORGANIC', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: VTokens.green700, letterSpacing: .5)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _headline(Product p) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.origin != null)
              Text(p.origin!.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700, letterSpacing: .5)),
            Text(p.name, style: AppTheme.serif(size: 30, letterSpacing: -.5)),
            const SizedBox(height: 4),
            Text('Hand-picked · ${p.weightLabel}', style: const TextStyle(fontSize: 13, color: VTokens.ink3)),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('₹${p.priceRupees}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: VTokens.ink)),
          if (p.mrpRupees != null && p.mrpRupees! > p.priceRupees)
            Text('₹${p.mrpRupees}', style: const TextStyle(fontSize: 12, color: VTokens.ink3, decoration: TextDecoration.lineThrough)),
          if (p.discountPercent > 0) ...[
            const SizedBox(height: 4),
            VBadge(label: 'SAVE ${p.discountPercent}%', tone: 'orange'),
          ],
        ],
      ),
    ],
  );

  Widget _metaRow(Product p) => Wrap(
    spacing: 8, runSpacing: 8,
    children: [
      _pill(Icons.star, '${p.rating} · ${p.reviewCount}', color: VTokens.amber500),
      _pill(Icons.local_shipping_outlined, '${p.etaMinutes} min', color: VTokens.green700),
      if (p.isOrganic) _pill(Icons.eco_outlined, 'Organic', color: VTokens.green700),
    ],
  );

  Widget _pill(IconData icon, String label, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: VTokens.surface, borderRadius: BorderRadius.circular(99),
      border: Border.all(color: VTokens.line2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color ?? VTokens.ink2),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: VTokens.ink2)),
    ]),
  );

  Widget _packs(Product p) {
    final packs = p.packOptions;
    if (packs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose pack', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink2)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(packs.length, (i) {
            final pk = packs[i] as Map<String, dynamic>;
            final active = i == _packIdx;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == packs.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _packIdx = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? VTokens.green25 : VTokens.surface,
                      border: Border.all(color: active ? VTokens.green : VTokens.line, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (pk['best'] == true)
                          Positioned(top: -16, right: -6, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(4)),
                            child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(pk['weight']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: VTokens.ink)),
                            Padding(padding: const EdgeInsets.only(top: 1), child: Text(pk['sub']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: VTokens.ink3))),
                            const SizedBox(height: 4),
                            Text('₹${((pk['price'] as num) / 100).round()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? VTokens.green700 : VTokens.ink2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _nutrition(Product p) {
    final n = p.nutrition;
    if (n.isEmpty) return const SizedBox.shrink();
    final order = ['kcal', 'carbs', 'vitC', 'fiber'];
    final entries = order.where((k) => n[k] != null).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Nutrition · per 100g', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink2)),
            Text('See all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: entries.map((k) {
            final pretty = {'kcal':'kcal','carbs':'carbs','vitC':'vit C','fiber':'fiber'}[k]!;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VTokens.line2)),
                  child: Column(children: [
                    Text('${n[k]}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: VTokens.ink)),
                    const SizedBox(height: 1),
                    Text(pretty, style: const TextStyle(fontSize: 10, color: VTokens.ink3)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _about(Product p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink2)),
      const SizedBox(height: 8),
      Text(p.description ?? '—',
        style: const TextStyle(fontSize: 13, color: VTokens.ink2, height: 1.55)),
    ],
  );

  Widget _reviews() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Reviews · 2,142', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink2)),
          Text('See all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.line2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFE0E7FF), shape: BoxShape.circle),
              child: const Text('AS', style: TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text.rich(TextSpan(text: 'Anita S. · ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  children: [TextSpan(text: 'verified buyer', style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w700))],
                )),
                SizedBox(height: 2),
                Text('2 days ago · 6th order', style: TextStyle(fontSize: 10, color: VTokens.ink3)),
              ],
            )),
            Row(children: List.generate(5, (_) => const Icon(Icons.star, size: 11, color: VTokens.amber500))),
          ]),
          const SizedBox(height: 8),
          const Text('"Tastes exactly like the ones my grandma used to bring from the village. Worth every rupee."',
            style: TextStyle(fontSize: 13, color: VTokens.ink2, height: 1.5)),
        ]),
      ),
    ],
  );
}
