import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/cart_bar.dart';
import 'browse/home_screen.dart';
import 'browse/categories_screen.dart';
import 'commerce/cart_screen.dart';
import 'commerce/checkout_screen.dart';
import 'product/wishlist_screen.dart';
import 'account/profile_screen.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      // The bottom nav is its own widget anchored at the bottom of the stack
      // — by stacking it manually (instead of using bottomNavigationBar) we
      // can let the new colourful header bleed under the status bar while
      // keeping content from hiding behind the nav.
      body: Stack(
        children: [
          Positioned.fill(child: IndexedStack(index: _index, children: _pages)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_index != 2) const GlobalCartBar(), // Don't show on Cart tab
                VBottomNav(
                  activeIndex: _index,
                  onChange: (i) => setState(() => _index = i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

