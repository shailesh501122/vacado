/// Public config the backend hands the mobile app on boot.
class RemoteConfig {
  final FirebasePublicConfig firebase;
  final bool otpDevBypass;

  const RemoteConfig({required this.firebase, required this.otpDevBypass});

  factory RemoteConfig.empty() => const RemoteConfig(
    firebase: FirebasePublicConfig.empty(),
    otpDevBypass: true,
  );

  factory RemoteConfig.fromJson(Map<String, dynamic> j) => RemoteConfig(
    firebase: FirebasePublicConfig.fromJson(
      Map<String, dynamic>.from((j['firebase'] as Map?) ?? const {}),
    ),
    otpDevBypass: ((j['features'] as Map?)?['otpDevBypass'] as bool?) ?? false,
  );
}

class FirebasePublicConfig {
  final bool enabled;
  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String iosAppId;
  final String iosBundleId;
  final String androidPackageName;

  const FirebasePublicConfig({
    required this.enabled,
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    required this.iosAppId,
    required this.iosBundleId,
    required this.androidPackageName,
  });

  const FirebasePublicConfig.empty()
      : enabled = false,
        apiKey = '',
        appId = '',
        projectId = '',
        messagingSenderId = '',
        iosAppId = '',
        iosBundleId = '',
        androidPackageName = '';

  factory FirebasePublicConfig.fromJson(Map<String, dynamic> j) => FirebasePublicConfig(
    enabled: (j['enabled'] as bool?) ?? false,
    apiKey: (j['apiKey'] as String?) ?? '',
    appId: (j['appId'] as String?) ?? '',
    projectId: (j['projectId'] as String?) ?? '',
    messagingSenderId: (j['messagingSenderId'] as String?) ?? '',
    iosAppId: (j['iosAppId'] as String?) ?? '',
    iosBundleId: (j['iosBundleId'] as String?) ?? '',
    androidPackageName: (j['androidPackageName'] as String?) ?? '',
  );

  bool get isConfigured =>
      enabled && apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
}
