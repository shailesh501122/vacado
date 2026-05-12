import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              _header(cart),
              Expanded(
                child: cart.state.items.isEmpty
                  ? _empty(context)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 140),
                      children: [
                        _etaBanner(),
                        _items(cart, context),
                        _coupon(cart),
                        _bill(cart.state.summary),
                      ],
                    ),
              ),
            ],
          ),
          if (cart.state.items.isNotEmpty)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _checkoutBar(context, cart.state.summary),
            ),
        ],
      ),
    );
  }

  Widget _header(CartProvider c) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
    child: Row(children: [
      IconBox(icon: Icons.shopping_bag_outlined),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your cart', style: AppTheme.serif(size: 22, letterSpacing: -.3)),
            Padding(padding: const EdgeInsets.only(top: 1),
              child: Text('${c.itemCount} items · delivery to Indiranagar',
                style: const TextStyle(fontSize: 11, color: VTokens.ink3))),
          ],
        ),
      ),
    ]),
  );

  Widget _etaBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.local_shipping_outlined, color: VTokens.green700, size: 16),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(TextSpan(
            text: 'Delivery in ',
            style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800, fontSize: 12.5),
            children: [
              TextSpan(text: '12 minutes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              TextSpan(text: ' · FREE'),
            ],
          )),
        ),
      ]),
    ),
  );

  Widget _items(CartProvider c, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: VTokens.surface, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VTokens.line2),
        ),
        child: Column(
          children: List.generate(c.state.items.length, (i) {
            final item = c.state.items[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: i == c.state.items.length - 1 ? Colors.transparent : VTokens.line2,
                )),
              ),
              child: Row(children: [
                FruitTile(kind: item.product.fruitKind, size: 50, radius: 10, blobScale: .68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink)),
                      const SizedBox(height: 1),
                      Text('${item.product.etaMinutes} min · sold by Vacado farms', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${(item.lineTotalPaise / 100).round()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    QtyStepper(
                      qty: item.quantity,
                      onDecrement: () => c.setQty(item.product.id, item.quantity - 1),
                      onIncrement: () => c.setQty(item.product.id, item.quantity + 1),
                    ),
                  ],
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }

  Widget _coupon(CartProvider c) {
    final code = c.state.couponCode;
    if (code == null) return const SizedBox(height: 18);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VTokens.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VTokens.line, width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(children: [
          const Icon(Icons.confirmation_number_outlined, color: VTokens.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Applied $code · save ₹${(c.state.summary.discountPaise / 100).round()}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: VTokens.ink)),
                const Text('Auto-applied', style: TextStyle(fontSize: 11, color: VTokens.ink3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VTokens.ink3, size: 16),
        ]),
      ),
    );
  }

  Widget _bill(CartSummary s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BILL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.line2)),
            child: Column(children: [
              _billRow('Item subtotal', '₹${(s.subtotalPaise / 100).round()}'),
              _billRow('Delivery fee', 'FREE', strike: '₹20'),
              _billRow('Handling charge', '₹${(s.handlingPaise / 100).round()}'),
              if (s.discountPaise > 0) _billRow('Coupon discount', '−₹${(s.discountPaise / 100).round()}', tone: 'green'),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: VTokens.line)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                Text('₹${(s.totalPaise / 100).round()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ]),
            ]),
          ),
          if (s.youSavePaise > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text("🌱 You're saving ₹${(s.youSavePaise / 100).round()} on this order",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {String? strike, String tone = 'default'}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: VTokens.ink2)),
        Row(children: [
          if (strike != null) Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(strike, style: const TextStyle(color: VTokens.ink3, decoration: TextDecoration.lineThrough, fontSize: 12)),
          ),
          Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: tone == 'green' ? VTokens.green700 : VTokens.ink,
          )),
        ]),
      ],
    ),
  );

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.shopping_bag_outlined, size: 60, color: VTokens.line),
        const SizedBox(height: 12),
        Text('Your cart is empty', style: AppTheme.serif(size: 24, letterSpacing: -.4)),
        const SizedBox(height: 8),
        const Text('Pick up some fresh fruit and we will deliver it in 10 min.',
          style: TextStyle(fontSize: 13, color: VTokens.ink3, height: 1.5), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _checkoutBar(BuildContext context, CartSummary s) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: VTokens.line2)),
    ),
    child: ElevatedButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
      style: ElevatedButton.styleFrom(
        backgroundColor: VTokens.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        minimumSize: const Size.fromHeight(56),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${(s.totalPaise / 100).round()} · ${s.itemCount} items',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70)),
              const Text('Proceed to checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          Row(children: const [
            Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
            Icon(Icons.chevron_right_rounded),
          ]),
        ],
      ),
    ),
  );
}
