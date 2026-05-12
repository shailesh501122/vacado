import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_client.dart';
import '../data/repositories.dart';
import '../models/user.dart';

const _kTokenKey = 'vc_token';
const _kPhoneKey = 'vc_phone';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._repo);
  final ApiClient _api;
  final AuthRepository _repo;

  String? _token;
  UserProfile? _user;
  bool _loading = false;
  String? _error;
  String? _pendingPhone;
  String? _devCode;

  bool get isLoggedIn => _token != null && _user != null;
  UserProfile? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  String? get pendingPhone => _pendingPhone;
  String? get devCode => _devCode;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    if (_token != null) {
      _api.setToken(_token);
      try {
        _user = await _repo.me();
      } catch (_) {
        _token = null;
        await prefs.remove(_kTokenKey);
        _api.setToken(null);
      }
    }
    notifyListeners();
  }

  Future<void> requestOtp(String phone) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await _repo.requestOtp(phone);
      _pendingPhone = phone;
      _devCode = res['devCode'] as String?;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> verifyOtp(String code, {String? name}) async {
    if (_pendingPhone == null) return;
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await _repo.verifyOtp(phone: _pendingPhone!, code: code, name: name);
      _token = res.token;
      _user = res.user;
      _api.setToken(_token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, _token!);
      await prefs.setString(_kPhoneKey, _user!.phone);
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> signOut() async {
    _token = null; _user = null; _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    notifyListeners();
  }
}
