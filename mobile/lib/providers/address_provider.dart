import 'package:flutter/foundation.dart';
import '../data/repositories.dart';
import '../models/address.dart';

class AddressProvider extends ChangeNotifier {
  AddressProvider(this._repo);
  final AddressRepository _repo;

  List<Address> addresses = const [];
  bool loading = false;
  String? error;

  Address? get defaultAddress =>
      addresses.where((a) => a.isDefault).isNotEmpty ? addresses.firstWhere((a) => a.isDefault) :
      (addresses.isNotEmpty ? addresses.first : null);

  Future<void> refresh() async {
    loading = true; notifyListeners();
    try {
      addresses = await _repo.list();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final a = await _repo.create(body);
    await refresh();
    return a;
  }

  Future<void> setDefault(String id) async {
    await _repo.setDefault(id);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}
