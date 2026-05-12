import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/repositories.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/address_provider.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

class VacadoApp extends StatelessWidget {
  const VacadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider(create: (_) => CatalogRepository(api)),
        Provider(create: (_) => CartRepository(api)),
        Provider(create: (_) => AddressRepository(api)),
        Provider(create: (_) => OrderRepository(api)),
        Provider(create: (_) => WishlistRepository(api)),
        Provider(create: (_) => CouponRepository(api)),
        ChangeNotifierProvider(create: (ctx) {
          final p = AuthProvider(api, AuthRepository(api));
          p.hydrate();
          return p;
        }),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (ctx) => CartProvider(ctx.read<CartRepository>()),
          update: (ctx, auth, prev) {
            final p = prev ?? CartProvider(ctx.read<CartRepository>());
            if (auth.isLoggedIn) { p.refresh(); }
            return p;
          },
        ),
        ChangeNotifierProvider(create: (ctx) => CatalogProvider(ctx.read<CatalogRepository>())..loadHome()),
        ChangeNotifierProxyProvider<AuthProvider, AddressProvider>(
          create: (ctx) => AddressProvider(ctx.read<AddressRepository>()),
          update: (ctx, auth, prev) {
            final p = prev ?? AddressProvider(ctx.read<AddressRepository>());
            if (auth.isLoggedIn) p.refresh();
            return p;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Vacado',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _RootGate(),
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/login':      (_) => const LoginScreen(),
          '/main':       (_) => const MainShell(),
        },
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();
  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const MainShell();
    return const OnboardingScreen();
  }
}
