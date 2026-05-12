import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: VTokens.ink,
      displayColor: VTokens.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: VTokens.bg,
      primaryColor: VTokens.green,
      colorScheme: base.colorScheme.copyWith(
        primary: VTokens.green,
        secondary: VTokens.orange,
        surface: VTokens.surface,
        onPrimary: Colors.white,
        onSurface: VTokens.ink,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: VTokens.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: VTokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: VTokens.ink),
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Serif headlines (Instrument Serif italic) — used for the editorial titles.
  static TextStyle serif({
    double size = 24,
    Color color = VTokens.ink,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = -.3,
  }) {
    return GoogleFonts.instrumentSerif(
      fontStyle: FontStyle.italic,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: 1.05,
    );
  }

  static TextStyle mono({double size = 9, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color ?? VTokens.ink.withOpacity(.55),
      letterSpacing: .4,
      fontWeight: FontWeight.w500,
    );
  }
}
