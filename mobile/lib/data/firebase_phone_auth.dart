import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/remote_config.dart';

/// Initialises Firebase from the runtime config the backend gives us, and
/// wraps the phone-auth flow with two simple steps.
class FirebasePhoneAuth {
  FirebaseAuth? _auth;
  String? _verificationId;
  int? _resendToken;
  FirebasePublicConfig? _config;

  bool get isInitialised => _auth != null;
  FirebasePublicConfig? get config => _config;

  Future<void> init(FirebasePublicConfig config) async {
    if (!config.isConfigured) return;
    _config = config;

    final options = FirebaseOptions(
      apiKey: config.apiKey,
      appId: config.appId,
      messagingSenderId: config.messagingSenderId,
      projectId: config.projectId,
      iosBundleId: config.iosBundleId.isEmpty ? null : config.iosBundleId,
    );

    // If a previous tenant's Firebase was already booted, recreate the [DEFAULT] app.
    final existing = Firebase.apps.where((a) => a.name == '[DEFAULT]').toList();
    if (existing.isNotEmpty && existing.first.options.projectId != config.projectId) {
      await existing.first.delete();
    }

    if (Firebase.apps.where((a) => a.name == '[DEFAULT]').isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    _auth = FirebaseAuth.instanceFor(app: Firebase.app());
  }

  Future<void> reset() async {
    _verificationId = null;
    _resendToken = null;
  }

  /// Kicks off the OTP send and resolves once [codeSent] has fired.
  /// On Android the SDK may auto-resolve and short-circuit the SMS flow —
  /// in that case [autoIdToken] resolves with a usable Firebase ID token.
  Future<({String? autoIdToken, int? resendToken})> sendOtp(String phoneE164) async {
    if (_auth == null) {
      throw StateError('Firebase phone auth is not configured for this instance');
    }

    final completer = Completer<({String? autoIdToken, int? resendToken})>();

    await _auth!.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCred = await _auth!.signInWithCredential(credential);
          final token = await userCred.user?.getIdToken(true);
          if (!completer.isCompleted) {
            completer.complete((autoIdToken: token, resendToken: _resendToken));
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete((autoIdToken: null, resendToken: resendToken));
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Verifies the code the user typed and returns a Firebase ID token.
  Future<String> verifyOtp(String code) async {
    if (_auth == null) {
      throw StateError('Firebase phone auth is not configured');
    }
    if (_verificationId == null) {
      throw StateError('Call sendOtp before verifyOtp');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!, smsCode: code,
    );
    final userCred = await _auth!.signInWithCredential(credential);
    final token = await userCred.user?.getIdToken(true);
    if (token == null) throw StateError('Firebase did not return an ID token');
    return token;
  }

  Future<void> signOut() async {
    try { await _auth?.signOut(); } catch (_) {}
  }
}
