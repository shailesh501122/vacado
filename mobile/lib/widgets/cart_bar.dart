import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/tokens.dart';
import '../screens/commerce/checkout_screen.dart';

class GlobalCartBar extends StatelessWidget {
  final bool floating;
  const GlobalCartBar({super.key, this.floating = true});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final s = cart.state.summary;
    if (cart.state.items.isEmpty) return const SizedBox.shrink();

    final content = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VTokens.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: VTokens.green.withOpacity(.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${s.itemCount} items · ₹${(s.totalPaise / 100).round()}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              const Text('View Cart', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          Row(children: const [
            Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, floating ? 16 : 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen())),
        child: content,
      ),
    );
  }
}
