import 'package:flutter/material.dart';

/// Vacado design tokens. Mirror of tokens.css from the design bundle.
class VTokens {
  static const Color green   = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF052E16);
  static const Color green50  = Color(0xFFDCFCE7);
  static const Color green25  = Color(0xFFF0FDF4);

  static const Color orange   = Color(0xFFFF7A00);
  static const Color orange50 = Color(0xFFFFF0E0);

  static const Color bg       = Color(0xFFF8FAFC);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color ink      = Color(0xFF0F172A);
  static const Color ink2     = Color(0xFF334155);
  static const Color ink3     = Color(0xFF64748B);
  static const Color line     = Color(0xFFE2E8F0);
  static const Color line2    = Color(0xFFF1F5F9);

  static const Color amber500 = Color(0xFFF59E0B);
  static const Color rose600  = Color(0xFFE11D48);
  static const Color rose700  = Color(0xFFB91C1C);

  static const double rSm  = 10;
  static const double r    = 16;
  static const double rLg  = 22;
  static const double rXl  = 28;

  static List<BoxShadow> shadow1 = [
    const BoxShadow(color: Color(0x0D0F172A), blurRadius: 2,  offset: Offset(0, 1)),
    const BoxShadow(color: Color(0x0A0F172A), blurRadius: 8,  offset: Offset(0, 2)),
  ];

  static List<BoxShadow> shadow2 = [
    const BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4)),
    const BoxShadow(color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> softUp = [
    const BoxShadow(
      color: Color(0x2E0F172A), blurRadius: 40, spreadRadius: -22, offset: Offset(0, 18),
    ),
  ];
}

/// Fruit palette — abstract color tiles instead of SVG illustrations.
class FruitPalette {
  final Color tile;
  final Color blob;
  final String caption;
  const FruitPalette(this.tile, this.blob, this.caption);
}

const Map<String, FruitPalette> kFruitPalette = {
  'apple':       FruitPalette(Color(0xFFFFE4E1), Color(0xFFE63946), 'apple'),
  'banana':      FruitPalette(Color(0xFFFFF6D6), Color(0xFFF4C430), 'banana'),
  'strawberry':  FruitPalette(Color(0xFFFFE0E6), Color(0xFFE11D48), 'strawberry'),
  'orange':      FruitPalette(Color(0xFFFFE8CC), Color(0xFFFB7B24), 'orange'),
  'kiwi':        FruitPalette(Color(0xFFE4F3D9), Color(0xFF7CB518), 'kiwi'),
  'blueberry':   FruitPalette(Color(0xFFDCE3F5), Color(0xFF3B5BDB), 'blueberry'),
  'grape':       FruitPalette(Color(0xFFE8DEF5), Color(0xFF7C3AED), 'grapes'),
  'watermelon':  FruitPalette(Color(0xFFFFD9DD), Color(0xFFEF4444), 'watermelon'),
  'mango':       FruitPalette(Color(0xFFFFEED0), Color(0xFFF59E0B), 'mango'),
  'pomegranate': FruitPalette(Color(0xFFFCDCDF), Color(0xFFB91C1C), 'pomegranate'),
  'avocado':     FruitPalette(Color(0xFFE4EED1), Color(0xFF4D7C0F), 'avocado'),
  'pineapple':   FruitPalette(Color(0xFFFFF1B8), Color(0xFFEAB308), 'pineapple'),
  'papaya':      FruitPalette(Color(0xFFFFE0CC), Color(0xFFF97316), 'papaya'),
  'spinach':     FruitPalette(Color(0xFFD8EAD0), Color(0xFF15803D), 'spinach'),
  'carrot':      FruitPalette(Color(0xFFFFE0CC), Color(0xFFEA580C), 'carrot'),
  'tomato':      FruitPalette(Color(0xFFFFE0E0), Color(0xFFDC2626), 'tomato'),
  'cucumber':    FruitPalette(Color(0xFFDAEFD6), Color(0xFF65A30D), 'cucumber'),
  'juice':       FruitPalette(Color(0xFFFFEFCB), Color(0xFFF97316), 'cold-pressed'),
  'greens':      FruitPalette(Color(0xFFE2F2D7), Color(0xFF22C55E), 'leafy greens'),
  'almond':      FruitPalette(Color(0xFFF1E4D2), Color(0xFFC2956B), 'almonds'),
  'cherry':      FruitPalette(Color(0xFFFCD9DC), Color(0xFFBE123C), 'cherry'),
  'lemon':       FruitPalette(Color(0xFFFFF8C7), Color(0xFFEAB308), 'lemon'),
  'pear':        FruitPalette(Color(0xFFE8EFD0), Color(0xFFA3B042), 'pear'),
  'dragonfruit': FruitPalette(Color(0xFFFFD9EC), Color(0xFFEC4899), 'dragon fruit'),
};

FruitPalette fruitFor(String? kind) =>
  kFruitPalette[kind ?? 'apple'] ?? kFruitPalette['apple']!;
