import 'package:flutter/foundation.dart';
import '../data/repositories.dart';
import '../models/cart.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._repo);
  final CartRepository _repo;

  CartState state = CartState.empty();
  bool loading = false;
  String? error;

  int get itemCount => state.summary.itemCount;

  int qtyOf(String productId) {
    for (final i in state.items) {
      if (i.product.id == productId) return i.quantity;
    }
    return 0;
  }

  Future<void> refresh() async {
    loading = true; notifyListeners();
    try {
      state = await _repo.get();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> add(String productId, {int qty = 1}) async {
    final prev = state;
    try {
      state = await _repo.add(productId, qty);
      notifyListeners();
    } catch (e) {
      state = prev; error = e.toString(); notifyListeners();
    }
  }

  Future<void> setQty(String productId, int qty) async {
    final prev = state;
    try {
      state = await _repo.setQty(productId, qty);
      notifyListeners();
    } catch (e) {
      state = prev; error = e.toString(); notifyListeners();
    }
  }

  Future<void> clear() async {
    state = CartState.empty();
    notifyListeners();
    try { await _repo.clear(); } catch (_) {}
  }
}
