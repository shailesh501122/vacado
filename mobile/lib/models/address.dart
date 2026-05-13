class Address {
  final String id;
  final String tag;
  final String icon;
  final String line1;
  final String? line2;
  final String city;
  final String pincode;
  final String? phone;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.tag,
    required this.icon,
    required this.line1,
    this.line2,
    required this.city,
    required this.pincode,
    this.phone,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'] as String,
    tag: j['tag'] as String,
    icon: (j['icon'] as String?) ?? 'home',
    line1: j['line1'] as String,
    line2: j['line2'] as String?,
    city: j['city'] as String,
    pincode: j['pincode'] as String,
    phone: j['phone'] as String?,
    isDefault: (j['isDefault'] as bool?) ?? false,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );

  String get fullLine {
    final p = [line1, if (line2 != null && line2!.isNotEmpty) line2!].join(', ');
    return p;
  }
}
