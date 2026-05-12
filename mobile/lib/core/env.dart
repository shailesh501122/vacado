/// Environment configuration. Override with --dart-define when building.
///
/// flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1
class Env {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  /// Show DEV-mode OTP code inside the app for easier QA.
  static const bool devShowOtp = bool.fromEnvironment('DEV_SHOW_OTP', defaultValue: true);
}
