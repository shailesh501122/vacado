import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../browse/offers_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'address_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.avatarInitial ?? user?.name?.substring(0, 1) ?? 'V').toUpperCase();

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _hero(context, initial, user?.name ?? 'Vacado guest', user?.phone ?? ''),
        Transform.translate(
          offset: const Offset(0, -12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VTokens.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VTokens.line2),
                boxShadow: VTokens.shadow1,
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [VTokens.orange, Color(0xFFB65419)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vacado Plus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                      Padding(padding: EdgeInsets.only(top: 1), child: Text('Free delivery · 5% extra off · renews May 28',
                        style: TextStyle(fontSize: 11, color: VTokens.ink3))),
                    ],
                  ),
                ),
                const Text('ACTIVE', style: TextStyle(color: VTokens.green700, fontSize: 11, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
          child: _menuGroup(context, 'Orders & rewards', [
            _MenuItem(Icons.shopping_bag_outlined, 'Your orders', '47 total · 1 active', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            _MenuItem(Icons.favorite_border_rounded, 'Wishlist', '5 items saved', () {}),
            _MenuItem(Icons.confirmation_number_outlined, 'Offers & coupons', '5 active', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OffersScreen()));
            }),
            _MenuItem(Icons.auto_awesome_rounded, 'Vacado Cash', '₹245 balance', () {}),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _menuGroup(context, 'Account', [
            _MenuItem(Icons.location_on_outlined, 'Addresses', '3 saved', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressScreen()));
            }),
            _MenuItem(Icons.credit_card_rounded, 'Payment methods', 'GPay default', () {}),
            _MenuItem(Icons.notifications_none_rounded, 'Notifications', 'price drops on', () {}),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: OutlinedButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const OnboardingScreen()), (_) => false);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: VTokens.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              foregroundColor: VTokens.rose700,
            ),
            child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, String initial, String name, String phone) => Container(
    padding: const EdgeInsets.fromLTRB(20, 54, 20, 28),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [VTokens.green900, VTokens.green700],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 56, height: 56, alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFE4E1), Color(0xFFFFD9DD)]),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.4), width: 2.5),
            ),
            child: Text(initial, style: const TextStyle(color: VTokens.rose700, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTheme.serif(size: 22, color: Colors.white, letterSpacing: -.3)),
                Text(phone, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.7))),
              ],
            ),
          ),
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle),
            child: const Icon(Icons.settings_outlined, size: 18, color: Colors.white),
          ),
        ]),
        const SizedBox(height: 22),
        Row(
          children: [
            _statTile('47', 'orders'),
            const SizedBox(width: 8),
            _statTile('₹2.1k', 'saved'),
            const SizedBox(width: 8),
            _statTile('12', 'streak days'),
          ],
        ),
      ],
    ),
  );

  Widget _statTile(String n, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(l, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(.7), fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _menuGroup(BuildContext context, String title, List<_MenuItem> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
      ),
      Container(
        decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: VTokens.line2)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(items.length, (i) {
            final m = items[i];
            return InkWell(
              onTap: m.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == items.length - 1 ? Colors.transparent : VTokens.line2))),
                child: Row(children: [
                  Container(
                    width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(10)),
                    child: Icon(m.icon, color: VTokens.green700, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                        Text(m.subtitle, style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: VTokens.ink3, size: 18),
                ]),
              ),
            );
          }),
        ),
      ),
    ],
  );
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _MenuItem(this.icon, this.title, this.subtitle, this.onTap);
}
