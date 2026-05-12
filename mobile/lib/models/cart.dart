import 'product.dart';

class CartItem {
  final String cartItemId;
  final int quantity;
  final Product product;
  final int lineTotalPaise;

  CartItem({required this.cartItemId, required this.quantity, required this.product, required this.lineTotalPaise});

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    cartItemId: j['cartItemId'] as String,
    quantity: (j['quantity'] as num).toInt(),
    product: Product.fromJson(j['product'] as Map<String, dynamic>),
    lineTotalPaise: (j['lineTotalPaise'] as num).toInt(),
  );
}

class CartSummary {
  final int itemCount;
  final int subtotalPaise;
  final int handlingPaise;
  final int deliveryFeePaise;
  final int discountPaise;
  final int totalPaise;
  final int youSavePaise;

  CartSummary({
    required this.itemCount,
    required this.subtotalPaise,
    required this.handlingPaise,
    required this.deliveryFeePaise,
    required this.discountPaise,
    required this.totalPaise,
    required this.youSavePaise,
  });

  factory CartSummary.empty() => CartSummary(
    itemCount: 0, subtotalPaise: 0, handlingPaise: 0, deliveryFeePaise: 0,
    discountPaise: 0, totalPaise: 0, youSavePaise: 0,
  );

  factory CartSummary.fromJson(Map<String, dynamic> j) => CartSummary(
    itemCount: (j['itemCount'] as num).toInt(),
    subtotalPaise: (j['subtotalPaise'] as num).toInt(),
    handlingPaise: (j['handlingPaise'] as num).toInt(),
    deliveryFeePaise: (j['deliveryFeePaise'] as num).toInt(),
    discountPaise: (j['discountPaise'] as num).toInt(),
    totalPaise: (j['totalPaise'] as num).toInt(),
    youSavePaise: (j['youSavePaise'] as num).toInt(),
  );
}

class CartState {
  final List<CartItem> items;
  final CartSummary summary;
  final String? couponCode;

  CartState({required this.items, required this.summary, this.couponCode});

  factory CartState.empty() => CartState(items: const [], summary: CartSummary.empty());

  factory CartState.fromJson(Map<String, dynamic> j) => CartState(
    items: ((j['items'] as List?) ?? []).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
    summary: CartSummary.fromJson((j['summary'] as Map<String, dynamic>?) ?? {
      'itemCount': 0, 'subtotalPaise': 0, 'handlingPaise': 0, 'deliveryFeePaise': 0,
      'discountPaise': 0, 'totalPaise': 0, 'youSavePaise': 0,
    }),
    couponCode: j['couponCode'] as String?,
  );
}
