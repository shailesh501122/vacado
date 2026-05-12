/// Environment configuration. Override with --dart-define when building.
///
///   # Production (default)
///   flutter run --release
///
///   # Local dev against a backend on the host machine
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1 \
///               --dart-define=DEV_SHOW_OTP=true
class Env {
  /// Production API. Override with `--dart-define=API_BASE=...` when developing.
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://161.118.165.248:4000/api/v1',
  );

  /// In production we do not surface the dev OTP bypass code on screen.
  /// Set to true with --dart-define=DEV_SHOW_OTP=true to enable it for QA.
  static const bool devShowOtp = bool.fromEnvironment('DEV_SHOW_OTP', defaultValue: false);

  /// App-wide brand strings.
  static const String appName = 'Vacado';
  static const String appVersion = '1.0.0';
}
