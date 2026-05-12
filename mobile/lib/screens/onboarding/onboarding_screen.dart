import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _hero(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTheme.serif(size: 38, letterSpacing: -.8),
                              children: [
                                const TextSpan(text: 'The freshest fruit,\n'),
                                TextSpan(text: 'at your doorstep', style: AppTheme.serif(size: 38, letterSpacing: -.8, color: VTokens.green700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Hand-picked daily from local farms. 10-minute delivery on everything organic.',
                            style: TextStyle(fontSize: 15, color: VTokens.ink2, fontWeight: FontWeight.w500, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          Row(children: [
                            Container(width: 24, height: 6, decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(99))),
                            const SizedBox(width: 6),
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: VTokens.line, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: VTokens.line, shape: BoxShape.circle)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  PrimaryBtn(
                    label: 'Get started', fullWidth: true,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already on Vacado? ',
                        style: TextStyle(fontSize: 13, color: VTokens.ink3),
                        children: [
                          TextSpan(text: 'Sign in', style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
    height: 420,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4), Colors.white],
        stops: [0, .6, 1],
      ),
    ),
    child: Stack(
      children: [
        Positioned(top: 110, left: 30, child: Transform.rotate(angle: -.21, child: const FruitTile(kind: 'strawberry', size: 130, radius: 28, blobScale: .78))),
        Positioned(top: 80, right: 26, child: Transform.rotate(angle: .14, child: const FruitTile(kind: 'orange', size: 150, radius: 32, blobScale: .76))),
        Positioned(top: 240, left: 90, child: Transform.rotate(angle: -.07, child: const FruitTile(kind: 'kiwi', size: 110, radius: 24, blobScale: .80))),
        Positioned(top: 280, right: 60, child: Transform.rotate(angle: .24, child: const FruitTile(kind: 'blueberry', size: 90, radius: 22, blobScale: .78))),
        Positioned(
          top: 60, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(999),
                boxShadow: VTokens.shadow1,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: VTokens.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x3322C55E), blurRadius: 0, spreadRadius: 4)])),
                const SizedBox(width: 8),
                const Text('DELIVERING IN ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VTokens.ink, letterSpacing: .3)),
                const Text('9:42', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VTokens.green700)),
              ]),
            ),
          ),
        ),
      ],
    ),
  );
}
