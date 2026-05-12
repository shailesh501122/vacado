import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.read<WishlistRepository>().list();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _items = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: VTokens.green))
              : (_items.isEmpty ? _empty() : _list()),
          ),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: VTokens.line)),
            child: const Icon(Icons.favorite_outline_rounded, size: 18, color: VTokens.rose600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your wishlist', style: AppTheme.serif(size: 22, letterSpacing: -.3)),
                Padding(padding: const EdgeInsets.only(top: 1),
                  child: Text('${_items.length} saved · 3 in stock now', style: const TextStyle(fontSize: 11, color: VTokens.ink3))),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          VChip(label: 'All · ${_items.length}', active: true),
          const SizedBox(width: 6),
          const VChip(label: 'In stock · 3'),
          const SizedBox(width: 6),
          const VChip(label: 'Price drops · 2'),
        ]),
      ],
    ),
  );

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_outline_rounded, size: 56, color: VTokens.line),
        const SizedBox(height: 12),
        Text('Nothing saved yet', style: AppTheme.serif(size: 24, letterSpacing: -.4)),
        const SizedBox(height: 8),
        const Text('Tap the ♡ on any product to save it for later.',
          textAlign: TextAlign.center, style: TextStyle(color: VTokens.ink3, fontSize: 13, height: 1.5)),
      ]),
    ),
  );

  Widget _list() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
    itemCount: _items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final w = _items[i];
      final p = w['product'] as Map<String, dynamic>;
      final inStock = (p['stock'] as num? ?? 100) > 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VTokens.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VTokens.line2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FruitTile(kind: p['fruitKind'] as String? ?? 'apple', size: 86, radius: 12, blobScale: .66),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VTokens.ink)),
                const SizedBox(height: 2),
                Text(p['weightLabel'] as String? ?? '', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                if (w['note'] != null && (w['note'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: inStock ? VTokens.green25 : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(5)),
                    child: Text((w['note'] as String).toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: inStock ? VTokens.green700 : VTokens.rose700, letterSpacing: .3)),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('₹${((p['pricePaise'] as num) / 100).round()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: VTokens.ink)),
                      if (p['mrpPaise'] != null && (p['mrpPaise'] as num) > (p['pricePaise'] as num))
                        Text('₹${((p['mrpPaise'] as num) / 100).round()}',
                          style: const TextStyle(fontSize: 10.5, color: VTokens.ink3, decoration: TextDecoration.lineThrough)),
                    ]),
                    OutlinedButton(
                      onPressed: inStock
                        ? () => context.read<CartProvider>().add(p['id'] as String)
                        : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: VTokens.green25,
                        side: const BorderSide(color: VTokens.green50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        foregroundColor: VTokens.green700,
                      ),
                      child: Text(inStock ? 'Add to cart' : 'Notify me', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VTokens.ink3),
            onPressed: () async {
              await context.read<WishlistRepository>().toggle(p['id'] as String);
              await _load();
            },
          ),
        ]),
      );
    },
  );
}
