import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_deeplink_sdk_platform_interface.dart';
import 'src/backend_client.dart';
import 'src/models.dart';
import 'src/sdk_config.dart';
import 'src/smart_linking.dart';

export 'src/backend_client.dart' show kDefaultDynamicLinkBaseUrl;
export 'src/exceptions.dart';
export 'src/models.dart';
export 'src/smart_linking.dart';

class MyDeeplinkSdk {
  Future<String?> getPlatformVersion() {
    return MyDeeplinkSdkPlatform.instance.getPlatformVersion();
  }

  static const MethodChannel _methodChannel = MethodChannel('my_deeplink_sdk_methods');
  static const EventChannel _eventChannel = EventChannel('my_deeplink_sdk_events');
  static const String _hasFirstInstallStorageKey = '@storage.hasFirstInstall';

  static MyDeeplinkSdkConfig? _config;
  static StreamSubscription<String>? _smartLinkSub;
  /// When non-empty, [extractShortCodeWithPathFallback] may use the last path
  /// segment as short code for these HTTPS hosts (e.g. `backend-dynamiclink.tecocraft.us`).
  static Set<String>? _pathShortCodeHosts;

  static DynamicLinkBackendClient get _backend => DynamicLinkBackendClient(_config);

  static const String _unknownManufacturer = 'Unknown Manufacturer';
  static const String _unknownDeviceModel = 'Unknown Device';
  static const String _unknownOsVersion = 'UNKNOWN';
  static const String _unknownAppName = 'MyApp';
  static const String _unknownAppVersion = '1.0.0';

  /// Initializes native hooks and stores config for HTTP APIs.
  ///
  /// **Backend-related keys** (optional unless noted):
  /// - `app_id` or `appId` — required for [postPendingRedirect].
  /// - `base_url` — override API origin (default: [kDefaultDynamicLinkBaseUrl]).
  /// - `app_display_name` — first part of User-Agent (default: `MyApp`).
  /// - `app_version` — version in User-Agent (default: `1.0.0`).
  /// - `device_model` — device label in User-Agent (default: `Unknown Device`).
  /// - `path_short_code_hosts` or `pathShortCodeHosts` — list of hosts where
  ///   `https://host/{code}` uses the last path segment as short code when
  ///   `short_code` query param is absent.
  static Future<void> init(Map<String, dynamic> config) async {
    final appIdentity = await _readAppIdentity();
    final configuredAppId = config['app_id'] as String? ?? config['appId'] as String?;
    final appId = _firstNonEmpty(configuredAppId, appIdentity.appId) ?? '';
    final baseRaw = config['base_url'] as String? ??
        config['baseUrl'] as String? ??
        kDefaultDynamicLinkBaseUrl;
    final base = baseRaw.trim().isEmpty ? kDefaultDynamicLinkBaseUrl : baseRaw.trim();
    final configuredDisplay = config['app_display_name'] as String? ?? config['appDisplayName'] as String?;
    final configuredVersion = config['app_version'] as String? ?? config['appVersion'] as String?;
    final display = _firstNonEmpty(configuredDisplay, appIdentity.appName) ?? _unknownAppName;
    final version = _firstNonEmpty(configuredVersion, appIdentity.appVersion) ?? _unknownAppVersion;
    final configuredManufacturer =
        config['device_manufacturer'] as String? ??
        config['deviceManufacturer'] as String?;
    final configuredModel =
        config['device_model'] as String? ?? config['deviceModel'] as String?;
    final configuredOsVersion =
        config['os_version'] as String? ?? config['osVersion'] as String?;

    final autoDevice = await _readDeviceIdentity();
    final deviceManufacturer = _firstNonEmpty(configuredManufacturer, autoDevice.manufacturer) ??
        _unknownManufacturer;
    final deviceModel = _firstNonEmpty(configuredModel, autoDevice.model) ?? _unknownDeviceModel;
    final osVersion = _firstNonEmpty(configuredOsVersion, autoDevice.osVersion) ?? _unknownOsVersion;

    _config = MyDeeplinkSdkConfig(
      appId: appId,
      baseUrl: base.replaceAll(RegExp(r'/+$'), ''),
      appDisplayName: display,
      appVersion: version,
      deviceManufacturer: deviceManufacturer,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );

    final hostList = config['path_short_code_hosts'] as List? ?? config['pathShortCodeHosts'] as List?;
    if (hostList == null || hostList.isEmpty) {
      _pathShortCodeHosts = null;
    } else {
      _pathShortCodeHosts = hostList
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (_pathShortCodeHosts!.isEmpty) _pathShortCodeHosts = null;
    }

    if (appId.isEmpty) {
      debugPrint(
        'MyDeeplinkSdk.init: app_id is empty — getLinkByCode will still work; '
        'postPendingRedirect() will throw until app_id is set.',
      );
    }

    try {
      await _methodChannel.invokeMethod<void>('init', config);
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize native SDK: ${e.message}');
    }
  }

  /// GET `https://…/api/links/code/{shortCode}` — resolves a short code to payload (JSON object).
  ///
  /// Does not require `app_id` if [init] was never called; uses [kDefaultDynamicLinkBaseUrl]
  /// and a fallback User-Agent unless [init] supplied better values.
  static Future<Map<String, dynamic>> getLinkByCode(String shortCode) {
    return _backend.getLinkByCode(shortCode);
  }

  /// Typed version of [getLinkByCode], using the live backend schema.
  static Future<DynamicLinkData> getLinkByCodeTyped(String shortCode) async {
    final envelope = await _backend.getLinkByCodeEnvelope(shortCode);
    final parsed = DynamicLinkEnvelope.fromJson(envelope);
    final data = parsed.data;
    if (data == null) {
      throw const FormatException('Expected non-null data for code lookup response');
    }
    return data;
  }

  /// RN parity alias for [getLinkByCode].
  static Future<Map<String, dynamic>> fetchDynamicLink(String shortCode) {
    return getLinkByCode(shortCode);
  }

  /// RN parity alias (typed).
  static Future<DynamicLinkData> fetchDynamicLinkTyped(String shortCode) {
    return getLinkByCodeTyped(shortCode);
  }

  /// POST `https://…/api/links/pending-redirect` with body:
  /// `{ "app_id": "…", "device_type": "ANDROID" | "IOS" }` and `User-Agent` header.
  ///
  /// Requires [init] with non-empty `app_id` / `appId`.
  static Future<Map<String, dynamic>> postPendingRedirect() {
    return _backend.postPendingRedirect();
  }

  /// Typed version of [postPendingRedirect], using the same model as code lookup.
  static Future<DynamicLinkData> postPendingRedirectTyped() async {
    final envelope = await _backend.postPendingRedirectEnvelope();
    final parsed = DynamicLinkEnvelope.fromJson(envelope);
    final data = parsed.data;
    if (data == null) {
      throw const FormatException('Expected non-null data for pending redirect response');
    }
    return data;
  }

  /// RN parity alias for [postPendingRedirect].
  static Future<Map<String, dynamic>> trackPendingRedirect() {
    return postPendingRedirect();
  }

  /// RN parity alias (typed).
  static Future<DynamicLinkData> trackPendingRedirectTyped() {
    return postPendingRedirectTyped();
  }

  /// Generates a public short link.
  /// POST `https://…/api/links/public-link`
  static Future<Map<String, dynamic>> generatePublicLink({
    required String clientId,
    required Map<String, dynamic> body,
  }) {
    return _backend.generatePublicLink(clientId: clientId, body: body);
  }

  /// Retrieves the link that opened the app if it was killed/closed.
  static Future<String?> getInitialLink() async {
    return _methodChannel.invokeMethod<String>('getInitialLink');
  }

  /// RN parity alias for [getInitialLink].
  static Future<String?> getInitialURL() {
    return getInitialLink();
  }

  static Stream<String> get onLinkStream {
    return _eventChannel.receiveBroadcastStream().cast<String>();
  }

  /// RN-style listener API for convenience.
  static Stream<String> addListener() => onLinkStream;

  /// Reads `short_code` from query string (URL-decoded).
  static String? extractShortCode(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final v = uri.queryParameters['short_code'];
    if (v != null && v.isNotEmpty) return v;
    return null;
  }

  /// Query `short_code` first; if missing and [allowedHosts] contains the URL host,
  /// uses the last non-empty path segment as short code (for `https://host/3SxE2G`).
  static String? extractShortCodeWithPathFallback(
    String url, {
    Set<String>? allowedHosts,
  }) {
    final fromQuery = extractShortCode(url);
    if (fromQuery != null) return fromQuery;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (allowedHosts == null || allowedHosts.isEmpty) return null;
    if (!allowedHosts.contains(uri.host)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final last = segments.last;
    if (RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(last) && last.length >= 4) {
      return last;
    }
    return null;
  }

  /// Returns true when first-install handling was already completed.
  static Future<bool> hasHandledFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasFirstInstallStorageKey) ?? false;
  }

  /// Clears first-install flag for QA/re-test flows.
  static Future<void> resetFirstInstallFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasFirstInstallStorageKey);
  }

  /// Starts RN-like smart linking flow:
  /// - one-time pending redirect check on first install
  /// - initial URL processing
  /// - runtime URL stream processing
  static Future<void> startSmartLinking({
    SmartLinkingOptions options = const SmartLinkingOptions(),
  }) async {
    await stopSmartLinking();

    await _handlePendingRedirectOnFirstInstall(options);

    try {
      final initialUrl = await getInitialURL();
      if (initialUrl != null && initialUrl.isNotEmpty) {
        await _handleIncomingUrl(initialUrl, options);
      }
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);
    }

    _smartLinkSub = onLinkStream.listen(
      (url) async {
        await _handleIncomingUrl(url, options);
      },
      onError: (Object error, StackTrace stackTrace) {
        options.onError?.call(error, stackTrace);
      },
    );
  }

  static Future<void> stopSmartLinking() async {
    await _smartLinkSub?.cancel();
    _smartLinkSub = null;
  }

  static Future<void> _handlePendingRedirectOnFirstInstall(
    SmartLinkingOptions options,
  ) async {
    final alreadyHandled = await hasHandledFirstInstall();
    if (alreadyHandled) {
      debugPrint('MyDeeplinkSdk.pendingRedirect: skipped (already handled).');
      return;
    }

    try {
      debugPrint('MyDeeplinkSdk.pendingRedirect: calling POST /api/links/pending-redirect');
      final data = await trackPendingRedirectTyped();
      debugPrint(
        'MyDeeplinkSdk.pendingRedirect: response '
        'dataShortCode=${data.shortCode} '
        'customData=${data.customData}',
      );
      options.onSuccess?.call(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasFirstInstallStorageKey, true);
    } on MyDeeplinkSdkNoPendingLinkException {
      // This is NORMAL — the backend simply has no pending deferred link for this device.
      // Android and iOS differ: iOS stores the intent natively; Android relies entirely
      // on the backend. If the user opened the app directly (not via a link), data is null.
      // We mark first-install as done so we don't keep calling the endpoint on every launch.
      debugPrint('MyDeeplinkSdk.pendingRedirect: No pending link — silently skipping.');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasFirstInstallStorageKey, true);
    } catch (error, stackTrace) {
      debugPrint('MyDeeplinkSdk.pendingRedirect: error $error');
      options.onError?.call(error, stackTrace);
    }
  }


  static Future<void> _handleIncomingUrl(
    String url,
    SmartLinkingOptions options,
  ) async {
    options.onUrl?.call(url);
    final shortCode = extractShortCodeWithPathFallback(
      url,
      allowedHosts: _pathShortCodeHosts,
    );
    if (shortCode == null) return;

    try {
      final data = await fetchDynamicLinkTyped(shortCode);
      options.onSuccess?.call(data);
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);
    }
  }

  /// Reserved for a future native/HTTP create flow. Prefer [getLinkByCode] / backend docs.
  static Future<String?> createShortLink(Map<String, dynamic> params) async {
    return _methodChannel.invokeMethod<String>('createShortLink', params);
  }

  static String? _firstNonEmpty(String? a, String? b) {
    final av = a?.trim();
    if (av != null && av.isNotEmpty) return av;
    final bv = b?.trim();
    if (bv != null && bv.isNotEmpty) return bv;
    return null;
  }

  static Future<_DeviceIdentity> _readDeviceIdentity() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return _DeviceIdentity(
          manufacturer: info.manufacturer,
          model: info.model,
          osVersion: info.version.release,
        );
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        return _DeviceIdentity(
          manufacturer: 'Apple',
          model: info.utsname.machine,
          osVersion: info.systemVersion,
        );
      }
    } catch (e) {
      debugPrint('MyDeeplinkSdk.init: device info unavailable: $e');
    }
    return const _DeviceIdentity();
  }

  static Future<_AppIdentity> _readAppIdentity() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final appId = _firstNonEmpty(info.packageName, info.packageName);
      final appName = _firstNonEmpty(info.appName, info.appName);
      final appVersion = _firstNonEmpty(info.version, info.version);
      return _AppIdentity(
        appId: appId,
        appName: appName,
        appVersion: appVersion,
      );
    } catch (e) {
      debugPrint('MyDeeplinkSdk.init: app info unavailable: $e');
      return const _AppIdentity();
    }
  }
}

class _DeviceIdentity {
  const _DeviceIdentity({
    this.manufacturer,
    this.model,
    this.osVersion,
  });

  final String? manufacturer;
  final String? model;
  final String? osVersion;
}

class _AppIdentity {
  const _AppIdentity({
    this.appId,
    this.appName,
    this.appVersion,
  });

  final String? appId;
  final String? appName;
  final String? appVersion;
}
