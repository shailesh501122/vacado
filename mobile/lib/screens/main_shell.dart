import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/bottom_nav.dart';
import 'browse/home_screen.dart';
import 'browse/categories_screen.dart';
import 'commerce/cart_screen.dart';
import 'product/wishlist_screen.dart';
import 'account/profile_screen.dart';

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
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: VBottomNav(
        activeIndex: _index,
        onChange: (i) => setState(() => _index = i),
      ),
    );
  }
}
