import 'package:flutter/foundation.dart';
import '../data/repositories.dart';
import '../models/product.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repo);
  final CatalogRepository _repo;

  List<Banner> banners = [];
  List<Product> bestsellers = [];
  List<Product> trending = [];
  List<Product> recommended = [];
  Map<String, dynamic> aiPick = const {};
  List<Category> categories = [];

  bool loadingHome = false;
  String? error;

  Future<void> loadHome() async {
    loadingHome = true; error = null; notifyListeners();
    try {
      final results = await Future.wait([_repo.home(), _repo.categories()]);
      final home = results[0] as Map<String, dynamic>;
      banners     = (home['banners']     as List).cast<Banner>();
      bestsellers = (home['bestsellers'] as List).cast<Product>();
      trending    = (home['trending']    as List).cast<Product>();
      recommended = (home['recommended'] as List).cast<Product>();
      aiPick      = Map<String, dynamic>.from(home['aiPick'] as Map);
      categories  = results[1] as List<Category>;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingHome = false; notifyListeners();
    }
  }

  Future<List<Product>> listFor({String? category, String? q, String sort = 'popular'}) {
    return _repo.products(category: category, q: q, sort: sort);
  }

  Future<Product> productDetails(String slug) => _repo.product(slug);

  Future<Map<String, dynamic>> search(String q) => _repo.search(q);
}
