import 'dart:io' show Platform;

/// Resolved at [MyDeeplinkSdk.init] from the host app.
class MyDeeplinkSdkConfig {
  MyDeeplinkSdkConfig({
    required this.appId,
    required this.baseUrl,
    required this.appDisplayName,
    required this.appVersion,
    required this.deviceManufacturer,
    required this.deviceModel,
    required this.osVersion,
  });

  /// Android package name or iOS bundle id (sent as `app_id` to pending-redirect).
  final String appId;

  /// API origin, no trailing slash.
  final String baseUrl;

  final String appDisplayName;
  final String appVersion;
  final String deviceManufacturer;
  final String deviceModel;
  final String osVersion;

  /// RN-like format: `(App/Version) (Manufacturer Model; ANDROID 14)`.
  String get userAgent {
    final os = _osName();
    return '($appDisplayName/$appVersion) ($deviceManufacturer $deviceModel; $os $osVersion)';
  }

  /// `ANDROID` or `IOS` for [device_type] in pending-redirect.
  String get deviceType {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'UNKNOWN';
  }

  String _osName() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return Platform.operatingSystem.toUpperCase();
  }
}
