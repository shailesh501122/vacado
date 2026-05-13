import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/tokens.dart';

class VBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onChange;
  const VBottomNav({super.key, required this.activeIndex, this.onChange});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.grid_view_rounded, 'Categories'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.favorite_border_rounded, 'Saved'),
    (Icons.person_outline_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final badge = context.select<CartProvider, int>((c) => c.itemCount);
    // Fully opaque pill anchored to the bottom safe area, with a subtle top
    // gradient so any content scrolled underneath fades to white before it
    // reaches the bar — content can no longer peek through.
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0), Colors.white],
          stops: const [0, .6],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 30, offset: const Offset(0, 8), spreadRadius: -8),
              BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6,  offset: const Offset(0, 2)),
            ],
            border: Border.all(color: VTokens.line2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_items.length, (i) {
              final active = i == activeIndex;
              final item = _items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChange?.call(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? VTokens.green25 : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.$1, size: 20, color: active ? VTokens.green700 : VTokens.ink3),
                            const SizedBox(height: 2),
                            Text(item.$2, style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: active ? VTokens.green700 : VTokens.ink3,
                            )),
                          ],
                        ),
                        if (i == 2 && badge > 0)
                          Positioned(
                            top: -2, right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              decoration: BoxDecoration(
                                color: VTokens.orange,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('$badge', textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Height the bar consumes including bottom safe area. Use this as the
  /// bottom padding inside scrollable screens so the last item never hides
  /// behind the nav.
  static double heightFor(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + 28 + 56;
}
