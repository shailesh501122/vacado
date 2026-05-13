import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/tokens.dart';
import 'fruit_tile.dart';
import 'primitives.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>((c) => c.qtyOf(product.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VTokens.line2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(child: FruitTile(kind: product.fruitKind, radius: 12, blobScale: .62, imageUrl: product.imageUrl)),
                  if (product.discountPercent > 0)
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: VTokens.orange, borderRadius: BorderRadius.circular(6)),
                        child: Text('${product.discountPercent}% OFF',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: .2),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 10, color: VTokens.ink),
                          const SizedBox(width: 3),
                          Text('${product.etaMinutes} min',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: VTokens.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 11, color: VTokens.amber500),
                const SizedBox(width: 3),
                Text(product.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VTokens.ink2)),
                Text(' · ${product.weightLabel}',
                  style: const TextStyle(fontSize: 10.5, color: VTokens.ink3)),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VTokens.ink, height: 1.2),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${product.priceRupees}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: VTokens.ink),
                      ),
                      if (product.mrpRupees != null && product.mrpRupees! > product.priceRupees)
                        Text('₹${product.mrpRupees}',
                          style: const TextStyle(
                            fontSize: 10.5, color: VTokens.ink3,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
                qty > 0
                  ? QtyStepper(
                      qty: qty,
                      onDecrement: () => context.read<CartProvider>().setQty(product.id, qty - 1),
                      onIncrement: () => context.read<CartProvider>().setQty(product.id, qty + 1),
                    )
                  : InkWell(
                      onTap: () => context.read<CartProvider>().add(product.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: VTokens.green25,
                          border: Border.all(color: VTokens.green50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ADD',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VTokens.green700, letterSpacing: .3),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
