import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/firebase_phone_auth.dart';
import '../data/remote_config_repo.dart';
import '../data/repositories.dart';
import '../models/remote_config.dart';
import '../models/user.dart';

const _kTokenKey = 'vc_token';
const _kPhoneKey = 'vc_phone';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._repo, this._cfgRepo, this._fb);

  final ApiClient _api;
  final AuthRepository _repo;
  final RemoteConfigRepository _cfgRepo;
  final FirebasePhoneAuth _fb;

  String? _token;
  UserProfile? _user;
  bool _loading = false;
  String? _error;
  String? _pendingPhone;
  RemoteConfig _config = RemoteConfig.empty();

  // public getters
  bool         get isLoggedIn    => _token != null && _user != null;
  UserProfile? get user          => _user;
  bool         get loading       => _loading;
  String?      get error         => _error;
  String?      get pendingPhone  => _pendingPhone;
  RemoteConfig get config        => _config;
  bool         get firebaseReady => _fb.isInitialised;
  bool         get firebaseConfigured => _config.firebase.isConfigured;

  /// On boot: load remote config, init Firebase if configured, then hydrate auth.
  Future<void> bootstrap() async {
    try {
      _config = await _cfgRepo.fetch();
      if (_config.firebase.isConfigured) {
        await _fb.init(_config.firebase);
      }
    } catch (e) {
      // Backend unreachable / no config yet — fall through. The login screen
      // will surface a friendly message.
      _error = 'Could not reach Vacado. Check your connection.';
    }

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

  Future<void> refreshConfig() async {
    try {
      _config = await _cfgRepo.fetch();
      if (_config.firebase.isConfigured && !_fb.isInitialised) {
        await _fb.init(_config.firebase);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ─── Firebase phone-auth flow ───────────────────────────────
  /// Sends an OTP via Firebase and returns true if the SDK already auto-resolved
  /// and signed the user in (Android instant verification).
  Future<bool> firebaseSendOtp(String phoneE164, {String? name}) async {
    _loading = true; _error = null; _pendingPhone = phoneE164; notifyListeners();
    try {
      final res = await _fb.sendOtp(phoneE164);
      if (res.autoIdToken != null) {
        await _exchange(res.autoIdToken!, name: name);
        return true;
      }
      return false;
    } catch (e) {
      _error = _readable(e);
      rethrow;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> firebaseVerifyOtp(String code, {String? name}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final idToken = await _fb.verifyOtp(code);
      await _exchange(idToken, name: name);
    } catch (e) {
      _error = _readable(e);
      rethrow;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> _exchange(String firebaseIdToken, {String? name}) async {
    final r = await _repo.firebaseLogin(idToken: firebaseIdToken, name: name);
    _token = r.token; _user = r.user;
    _api.setToken(_token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, _token!);
    await prefs.setString(_kPhoneKey, _user!.phone);
  }

  Future<void> signOut() async {
    _token = null; _user = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    try { await _fb.signOut(); } catch (_) {}
    notifyListeners();
  }

  String _readable(Object e) {
    final s = e.toString();
    if (s.contains('invalid-verification-code')) return 'That code didn\'t match. Try again.';
    if (s.contains('session-expired'))           return 'Code expired — request a new one.';
    if (s.contains('quota-exceeded'))            return 'Daily SMS limit hit. Try again tomorrow.';
    if (s.contains('network-request-failed'))    return 'Network error. Check your connection.';
    if (s.contains('firebase_not_configured'))   return 'Phone auth is not configured. Contact the admin.';
    return s.replaceFirst('Exception: ', '');
  }
}
