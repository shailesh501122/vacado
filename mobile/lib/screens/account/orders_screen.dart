import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/fruit_tile.dart';
import '../commerce/tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final list = await context.read<OrderRepository>().list();
      if (!mounted) return;
      setState(() { _orders = list; _loading = false; });
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(children: [
                VBackButton(onTap: () => Navigator.maybePop(context)),
                const SizedBox(width: 10),
                Text('Your orders', style: AppTheme.serif(size: 22, letterSpacing: -.3)),
              ]),
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: VTokens.green))
                : _orders.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(32),
                      child: Text('No orders yet — place one to see it here.', style: TextStyle(color: VTokens.ink3))))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 60),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _orderTile(_orders[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(OrderModel o) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: o.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.line2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _statusBg(o.status), borderRadius: BorderRadius.circular(4)),
                child: Text(o.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _statusFg(o.status))),
              ),
              const SizedBox(width: 8),
              Text(o.orderNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3)),
              const Spacer(),
              Text('₹${(o.totalPaise / 100).round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (final k in o.thumbs.take(5)) Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FruitTile(kind: k, size: 32, radius: 8, blobScale: .7),
              ),
              if (o.thumbs.length > 5)
                Text('+ ${o.thumbs.length - 5} more', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
            ]),
          ],
        ),
      ),
    );
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'delivered': return VTokens.green25;
      case 'cancelled': return const Color(0xFFFEE2E2);
      default: return const Color(0xFFFEF3C7);
    }
  }
  Color _statusFg(String s) {
    switch (s) {
      case 'delivered': return VTokens.green700;
      case 'cancelled': return VTokens.rose700;
      default: return const Color(0xFFB45309);
    }
  }
}
