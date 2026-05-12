class OrderItem {
  final String? productId;
  final String name;
  final String fruitKind;
  final String weightLabel;
  final int unitPricePaise;
  final int quantity;
  final int lineTotalPaise;

  OrderItem({
    this.productId,
    required this.name,
    required this.fruitKind,
    required this.weightLabel,
    required this.unitPricePaise,
    required this.quantity,
    required this.lineTotalPaise,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['productId'] as String?,
    name: j['name'] as String,
    fruitKind: (j['fruitKind'] as String?) ?? 'apple',
    weightLabel: (j['weightLabel'] as String?) ?? '',
    unitPricePaise: (j['unitPricePaise'] as num).toInt(),
    quantity: (j['quantity'] as num).toInt(),
    lineTotalPaise: (j['lineTotalPaise'] as num).toInt(),
  );
}

class OrderEvent {
  final String kind;
  final String title;
  final String? subtitle;
  final DateTime occurredAt;

  OrderEvent({required this.kind, required this.title, this.subtitle, required this.occurredAt});

  factory OrderEvent.fromJson(Map<String, dynamic> j) => OrderEvent(
    kind: j['kind'] as String,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    occurredAt: DateTime.parse(j['occurredAt'] as String),
  );
}

class RiderInfo {
  final String name;
  final String phone;
  final double rating;
  final String vehicle;
  RiderInfo({required this.name, required this.phone, required this.rating, required this.vehicle});
  factory RiderInfo.fromJson(Map<String, dynamic> j) => RiderInfo(
    name: j['name'] as String,
    phone: j['phone'] as String,
    rating: (j['rating'] as num).toDouble(),
    vehicle: j['vehicle'] as String,
  );
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final int subtotalPaise;
  final int discountPaise;
  final int deliveryFeePaise;
  final int handlingPaise;
  final int totalPaise;
  final String? couponCode;
  final String paymentMethod;
  final String paymentStatus;
  final int etaMinutes;
  final DateTime placedAt;
  final RiderInfo? rider;
  final List<OrderItem> items;
  final List<OrderEvent> events;
  final List<String> thumbs;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.deliveryFeePaise,
    required this.handlingPaise,
    required this.totalPaise,
    this.couponCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.etaMinutes,
    required this.placedAt,
    this.rider,
    this.items = const [],
    this.events = const [],
    this.thumbs = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'] as String,
    orderNumber: j['orderNumber'] as String,
    status: j['status'] as String,
    subtotalPaise: (j['subtotalPaise'] as num).toInt(),
    discountPaise: (j['discountPaise'] as num).toInt(),
    deliveryFeePaise: (j['deliveryFeePaise'] as num).toInt(),
    handlingPaise: (j['handlingPaise'] as num).toInt(),
    totalPaise: (j['totalPaise'] as num).toInt(),
    couponCode: j['couponCode'] as String?,
    paymentMethod: (j['paymentMethod'] as String?) ?? 'upi',
    paymentStatus: (j['paymentStatus'] as String?) ?? 'paid',
    etaMinutes: (j['etaMinutes'] as num?)?.toInt() ?? 12,
    placedAt: DateTime.parse(j['placedAt'] as String),
    rider: j['rider'] == null ? null : RiderInfo.fromJson(j['rider'] as Map<String, dynamic>),
    items: ((j['items'] as List?) ?? const []).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    events: ((j['events'] as List?) ?? const []).map((e) => OrderEvent.fromJson(e as Map<String, dynamic>)).toList(),
    thumbs: ((j['thumbs'] as List?) ?? const []).map((e) => e as String).toList(),
  );
}
