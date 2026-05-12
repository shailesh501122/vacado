import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import '../account/address_screen.dart';
import 'tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _slot = 'standard';
  String _instruction = 'Leave at door';
  String _payment = 'upi';
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().refresh();
    });
  }

  Future<void> _placeOrder() async {
    final addr = context.read<AddressProvider>().defaultAddress;
    if (addr == null) {
      _showSnack('Please add a delivery address');
      return;
    }
    setState(() => _placing = true);
    try {
      final repo = context.read<OrderRepository>();
      final order = await repo.place(
        addressId: addr.id,
        paymentMethod: _payment,
        slot: _slot,
        instruction: _instruction,
        couponCode: context.read<CartProvider>().state.couponCode,
      );
      await context.read<CartProvider>().refresh();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id)));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final addr = context.watch<AddressProvider>().defaultAddress;
    final cart = context.watch<CartProvider>();
    final total = cart.state.summary.totalPaise;

    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Row(children: [
                    VBackButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 10),
                    Text('Checkout', style: AppTheme.serif(size: 22, letterSpacing: -.3)),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 200),
                    children: [
                      _addressCard(addr),
                      const SizedBox(height: 12),
                      _slotCard(),
                      const SizedBox(height: 12),
                      _instructionCard(),
                      const SizedBox(height: 12),
                      _paymentCard(),
                      const SizedBox(height: 12),
                      _summaryCard(cart),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _placeBar(total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: VTokens.line2)),
    child: child,
  );

  Widget _cardLabel(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: VTokens.ink3, letterSpacing: .5));

  Widget _addressCard(Address? addr) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardLabel('Delivering to'),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_rounded, color: VTokens.green700, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: addr == null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('No address set', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressScreen())),
                    child: const Text('Add an address', style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${addr.tag} · 1.2 km away', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${addr.fullLine}, ${addr.city} ${addr.pincode}',
                    style: const TextStyle(fontSize: 12, color: VTokens.ink3, height: 1.4)),
                ]),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressScreen())),
            child: const Text('Change', style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
      ],
    ),
  );

  Widget _slotCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardLabel('Delivery slot'),
        const SizedBox(height: 8),
        Row(children: [
          _slotPill('standard', 'In 12 min', 'standard'),
          const SizedBox(width: 8),
          _slotPill('evening', '6 – 7 PM', 'scheduled'),
          const SizedBox(width: 8),
          _slotPill('tomorrow', 'Tomorrow', '8 – 9 AM'),
        ]),
      ],
    ),
  );

  Widget _slotPill(String key, String t, String sub) {
    final active = _slot == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _slot = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: active ? VTokens.green25 : Colors.transparent,
            border: Border.all(color: active ? VTokens.green : VTokens.line, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            Text(sub, style: const TextStyle(fontSize: 10, color: VTokens.ink3)),
          ]),
        ),
      ),
    );
  }

  Widget _instructionCard() {
    const opts = ['Leave at door', 'Avoid ringing bell', 'Hand to guard'];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel('Delivery instructions'),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ...opts.map((o) => GestureDetector(
              onTap: () => setState(() => _instruction = o),
              child: VChip(label: o, active: _instruction == o),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    final methods = [
      {'k': 'upi',  'icon': Icons.credit_card, 'title': 'UPI · GPay', 'sub': 'priya@oksbi'},
      {'k': 'card', 'icon': Icons.credit_card, 'title': 'HDFC Credit · 1234', 'sub': '5% cashback today'},
      {'k': 'cod',  'icon': Icons.shopping_bag_outlined, 'title': 'Cash on delivery', 'sub': 'pay rider at door'},
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel('Payment method'),
          const SizedBox(height: 6),
          ...methods.map((m) {
            final active = _payment == m['k'];
            return GestureDetector(
              onTap: () => setState(() => _payment = m['k'] as String),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: VTokens.line2))),
                child: Row(children: [
                  Container(
                    width: 36, height: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? VTokens.green25 : VTokens.line2, borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(m['icon'] as IconData, size: 18, color: active ? VTokens.green700 : VTokens.ink2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        Text(m['sub'] as String, style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                      ],
                    ),
                  ),
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: active ? VTokens.green : VTokens.line, width: active ? 6 : 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(CartProvider cart) {
    final thumbs = cart.state.items.take(5).map((i) => i.product.fruitKind).toList();
    final s = cart.state.summary;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardLabel('${s.itemCount} items · ${(s.totalPaise / 100).round()}'),
              const Text('View', style: TextStyle(color: VTokens.green700, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (final t in thumbs) Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FruitTile(kind: t, size: 38, radius: 8, blobScale: .7),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _placeBar(int totalPaise) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: VTokens.line2)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _placing ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: VTokens.green, foregroundColor: Colors.white,
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
                  Text(_placing ? 'Placing…' : 'Pay via ${_payment.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70)),
                  Text('Place order · ₹${(totalPaise / 100).round()}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('By placing the order you agree to our terms',
          style: TextStyle(fontSize: 11, color: VTokens.ink3)),
      ],
    ),
  );
}
