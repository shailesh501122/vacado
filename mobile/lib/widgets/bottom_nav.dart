import 'dart:ui';
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
    (Icons.grid_view_rounded, 'Browse'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.favorite_border_rounded, 'Saved'),
    (Icons.person_outline_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final badge = context.select<CartProvider, int>((c) => c.itemCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.85),
              borderRadius: BorderRadius.circular(26),
              boxShadow: VTokens.shadow2,
              border: Border.all(color: VTokens.line2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (i) {
                final active = i == activeIndex;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => onChange?.call(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? VTokens.green25 : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
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
                            top: -2, right: -6,
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
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
