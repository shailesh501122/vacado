import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vacado/core/env.dart';
import 'package:vacado/models/product.dart';
import 'package:vacado/models/cart.dart';
import 'package:vacado/widgets/fruit_tile.dart';
import 'package:vacado/widgets/primitives.dart';

void main() {
  group('Env', () {
    test('defaults point at production', () {
      expect(Env.apiBase, contains('161.118.165.248'));
      expect(Env.devShowOtp, isFalse);
      expect(Env.appName, 'Vacado');
    });
  });

  group('Product model', () {
    test('parses JSON and computes discount + rupees', () {
      final p = Product.fromJson({
        'id': 'a-1',
        'slug': 'alphonso',
        'name': 'Alphonso Mango',
        'fruitKind': 'mango',
        'weightLabel': '1 kg',
        'pricePaise': 45000,
        'mrpPaise': 59900,
        'discountPercent': 25,
        'rating': 4.9,
        'reviewCount': 2142,
        'etaMinutes': 12,
        'isOrganic': true,
        'isTrending': true,
        'isBestseller': true,
        'stock': 100,
        'nutrition': {'kcal': '60'},
        'packOptions': [],
      });
      expect(p.priceRupees, 450);
      expect(p.mrpRupees, 599);
      expect(p.discountPercent, 25);
      expect(p.isOrganic, isTrue);
    });
  });

  group('Cart model', () {
    test('empty summary is zeroed', () {
      final s = CartSummary.empty();
      expect(s.itemCount, 0);
      expect(s.totalPaise, 0);
    });
  });

  testWidgets('FruitTile renders at fixed size', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FruitTile(kind: 'apple', size: 64)),
    ));
    expect(find.byType(FruitTile), findsOneWidget);
  });

  testWidgets('PrimaryBtn renders and reacts to taps', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PrimaryBtn(label: 'Tap me', onPressed: () => tapped++)),
    ));
    expect(find.text('Tap me'), findsOneWidget);
    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(tapped, 1);
  });
}
