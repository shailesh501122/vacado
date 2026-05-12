import '../models/address.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await _api.post('/auth/request-otp', body: {'phone': phone});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<({String token, UserProfile user})> verifyOtp({
    required String phone, required String code, String? name,
  }) async {
    final res = await _api.post('/auth/verify-otp', body: {
      'phone': phone, 'code': code, if (name != null) 'name': name,
    });
    final m = Map<String, dynamic>.from(res as Map);
    return (
      token: m['token'] as String,
      user: UserProfile.fromJson(Map<String, dynamic>.from(m['user'] as Map)),
    );
  }

  Future<UserProfile> me() async {
    final res = await _api.get('/auth/me');
    final m = Map<String, dynamic>.from(res as Map);
    return UserProfile.fromJson(Map<String, dynamic>.from(m['user'] as Map));
  }
}

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> home() async {
    final res = await _api.get('/catalog/home');
    final m = Map<String, dynamic>.from(res as Map);
    return {
      'banners': ((m['banners'] as List?) ?? const []).map((e) => Banner.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      'bestsellers': ((m['bestsellers'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      'trending': ((m['trending'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      'recommended': ((m['recommended'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      'aiPick': m['aiPick'] ?? const {},
    };
  }

  Future<List<Category>> categories() async {
    final res = await _api.get('/catalog/categories');
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['categories'] as List?) ?? const []).map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<Product>> products({String? category, String? q, int limit = 40, String sort = 'popular'}) async {
    final res = await _api.get('/catalog/products', query: {
      if (category != null) 'category': category,
      if (q != null) 'q': q,
      'limit': limit,
      'sort': sort,
    });
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['products'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Product> product(String slug) async {
    final res = await _api.get('/catalog/products/$slug');
    final m = Map<String, dynamic>.from(res as Map);
    return Product.fromJson(Map<String, dynamic>.from(m['product'] as Map));
  }

  Future<Map<String, dynamic>> search(String q) async {
    final res = await _api.get('/catalog/search', query: {'q': q});
    final m = Map<String, dynamic>.from(res as Map);
    return {
      'products': ((m['products'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      'trending': ((m['trending'] as List?) ?? const []).map((e) => e.toString()).toList(),
    };
  }
}

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<CartState> get() async => CartState.fromJson(Map<String, dynamic>.from(await _api.get('/cart') as Map));
  Future<CartState> add(String productId, [int quantity = 1]) async =>
      CartState.fromJson(Map<String, dynamic>.from(await _api.post('/cart/items', body: {'productId': productId, 'quantity': quantity}) as Map));
  Future<CartState> setQty(String productId, int qty) async =>
      CartState.fromJson(Map<String, dynamic>.from(await _api.patch('/cart/items', body: {'productId': productId, 'quantity': qty}) as Map));
  Future<void> clear() async => _api.delete('/cart');
}

class AddressRepository {
  AddressRepository(this._api);
  final ApiClient _api;

  Future<List<Address>> list() async {
    final res = await _api.get('/addresses');
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['addresses'] as List?) ?? const []).map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final res = await _api.post('/addresses', body: body);
    return Address.fromJson(Map<String, dynamic>.from((res as Map)['address'] as Map));
  }

  Future<void> setDefault(String id) async => _api.post('/addresses/$id/default');
  Future<void> delete(String id) async => _api.delete('/addresses/$id');
}

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  Future<OrderModel> place({required String addressId, required String paymentMethod, String? couponCode, String? slot, String? instruction}) async {
    final res = await _api.post('/orders', body: {
      'addressId': addressId,
      'paymentMethod': paymentMethod,
      if (slot != null) 'deliverySlot': slot,
      if (instruction != null) 'deliveryInstruction': instruction,
      if (couponCode != null) 'couponCode': couponCode,
    });
    return OrderModel.fromJson(Map<String, dynamic>.from((res as Map)['order'] as Map));
  }

  Future<List<OrderModel>> list() async {
    final res = await _api.get('/orders');
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['orders'] as List?) ?? const []).map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<OrderModel> get(String id) async {
    final res = await _api.get('/orders/$id');
    return OrderModel.fromJson(Map<String, dynamic>.from((res as Map)['order'] as Map));
  }

  Future<Map<String, dynamic>> tracking(String id) async {
    final res = await _api.get('/orders/$id/track');
    return Map<String, dynamic>.from(res as Map);
  }
}

class WishlistRepository {
  WishlistRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get('/wishlist');
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['items'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<bool> toggle(String productId) async {
    final res = await _api.post('/wishlist/toggle', body: {'productId': productId});
    final m = Map<String, dynamic>.from(res as Map);
    return (m['saved'] as bool?) ?? false;
  }
}

class CouponRepository {
  CouponRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.get('/coupons');
    final m = Map<String, dynamic>.from(res as Map);
    return ((m['coupons'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
