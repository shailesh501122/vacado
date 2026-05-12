import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [VTokens.green, VTokens.green700, VTokens.green900],
            stops: [0, .7, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80, right: -80,
              child: _blob(320, Colors.white.withOpacity(.18)),
            ),
            Positioned(
              bottom: -100, left: -100,
              child: _blob(280, const Color(0xFFFF7A00).withOpacity(.35)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 60, spreadRadius: -20, offset: const Offset(0, 30))],
                    ),
                    alignment: Alignment.center,
                    child: const VacadoMark(size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('vacado', style: AppTheme.serif(size: 48, color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text('FRESH · IN 10 MIN',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.75), fontSize: 12,
                      letterSpacing: 4, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 64, left: 0, right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 24, height: 1, color: Colors.white.withOpacity(.4)),
                    const SizedBox(width: 8),
                    Text('farm-to-door · daily',
                      style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12, letterSpacing: .5),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 24, height: 1, color: Colors.white.withOpacity(.4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withOpacity(0)], stops: const [0, .7]),
    ),
  );
}
