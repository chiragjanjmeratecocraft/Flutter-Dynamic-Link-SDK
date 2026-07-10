import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'sdk_config.dart';

const String kDefaultDynamicLinkBaseUrl = 'https://backend-dynamiclink.tecocraft.us';
const Duration _kRequestTimeout = Duration(seconds: 15);

/// Calls Tecocraft dynamic-link HTTP APIs.
class DynamicLinkBackendClient {
  DynamicLinkBackendClient(this._config);

  final MyDeeplinkSdkConfig? _config;

  /// GET `/api/links/code/{shortCode}`
  Future<Map<String, dynamic>> getLinkByCode(String shortCode) async {
    final decoded = await getLinkByCodeEnvelope(shortCode);
    return _extractData(decoded);
  }

  /// GET `/api/links/code/{shortCode}` returning full API envelope.
  Future<Map<String, dynamic>> getLinkByCodeEnvelope(String shortCode) async {
    final code = shortCode.trim();
    if (code.isEmpty) {
      throw ArgumentError.value(shortCode, 'shortCode', 'must not be empty');
    }
    final base = _normalizeBase(_config?.baseUrl ?? kDefaultDynamicLinkBaseUrl);
    final uri = Uri.parse('$base/api/links/code/${Uri.encodeComponent(code)}');
    final headers = _headers(includeJsonAccept: true);
    _logRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
      params: <String, dynamic>{'short_code': code},
    );
    late final http.Response res;
    try {
      res = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(_kRequestTimeout);
    } on TimeoutException {
      debugPrint(
        'MyDeeplinkSdk.http timeout\n'
        '  method: GET\n'
        '  url: $uri\n'
        '  after: ${_kRequestTimeout.inSeconds}s',
      );
      rethrow;
    } catch (error) {
      debugPrint('MyDeeplinkSdk.http error\n  method: GET\n  url: $uri\n  error: $error');
      rethrow;
    }
    final decoded = _decodeJsonObject(res);
    _logResponse(method: 'GET', uri: uri, statusCode: res.statusCode, body: decoded);
    return decoded;
  }

  /// POST `/api/links/pending-redirect` with `app_id` and `device_type`.
  Future<Map<String, dynamic>> postPendingRedirect() {
    return postPendingRedirectEnvelope().then(_extractData);
  }

  /// POST `/api/links/pending-redirect` returning full API envelope.
  Future<Map<String, dynamic>> postPendingRedirectEnvelope() async {
    final config = _config;
    if (config == null) {
      throw StateError(
        'MyDeeplinkSdk.init() must be called with app_id before postPendingRedirect().',
      );
    }
    if (config.appId.isEmpty) {
      throw StateError(
        'MyDeeplinkSdk.init() must include a non-empty app_id (or appId).',
      );
    }
    final base = _normalizeBase(config.baseUrl);
    final uri = Uri.parse('$base/api/links/pending-redirect');
    final body = jsonEncode(<String, String>{
      'app_id': config.appId,
      'device_type': config.deviceType,
    });
    final headers = _headers(includeJsonAccept: false, contentTypeJson: true);
    _logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      params: jsonDecode(body) as Map<String, dynamic>,
    );

    try {
      final res = await http.post(uri, headers: headers, body: body).timeout(_kRequestTimeout);
      final decodedResponse = _decodeJsonObject(res);                          // fix 2: renamed variable
      _logResponse(method: 'POST', uri: uri, statusCode: res.statusCode, body: decodedResponse);

      final shortCode = decodedResponse['data']['short_code'];                 // fix 3: added semicolon
      debugPrint("this is short code after getting response $shortCode");

      final linkDecoded = await getLinkByCodeEnvelope(shortCode);              // fix 1: await works now, fix 2: renamed variable
      return linkDecoded;

    } on TimeoutException {
      debugPrint(
        'MyDeeplinkSdk.http timeout\n'
            '  method: POST\n'
            '  url: $uri\n'
            '  after: ${_kRequestTimeout.inSeconds}s',
      );
      rethrow;
    } catch (error) {
      debugPrint('MyDeeplinkSdk.http error\n  method: POST\n  url: $uri\n  error: $error');
      rethrow;
    }
  }

  /// POST `/api/links/public-link` with `clientId` and body.
  Future<Map<String, dynamic>> generatePublicLink({
    required String clientId,
    required Map<String, dynamic> body,
  }) async {
    final base = _normalizeBase(_config?.baseUrl ?? kDefaultDynamicLinkBaseUrl);
    final uri = Uri.parse('$base/api/links/public-link');
    final headers = _headers(includeJsonAccept: true, contentTypeJson: true);
    headers['clientId'] = clientId;

    _logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      params: body,
    );

    try {
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_kRequestTimeout);
      final decoded = _decodeJsonObject(res);
      _logResponse(method: 'POST', uri: uri, statusCode: res.statusCode, body: decoded);
      return decoded;
    } on TimeoutException {
      debugPrint(
        'MyDeeplinkSdk.http timeout\n'
            '  method: POST\n'
            '  url: $uri\n'
            '  after: ${_kRequestTimeout.inSeconds}s',
      );
      rethrow;
    } catch (error) {
      debugPrint('MyDeeplinkSdk.http error\n  method: POST\n  url: $uri\n  error: $error');
      rethrow;
    }
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> params,
  }) {
    debugPrint(
      'MyDeeplinkSdk.http request\n'
      '  method: $method\n'
      '  url: $uri\n'
      '  headers: $headers\n'
      '  params: $params',
    );
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, dynamic> body,
  }) {
    debugPrint(
      'MyDeeplinkSdk.http response\n'
      '  method: $method\n'
      '  url: $uri\n'
      '  statusCode: $statusCode\n'
      '  body: $body',
    );
  }

  Map<String, String> _headers({
    required bool includeJsonAccept,
    bool contentTypeJson = false,
  }) {
    final ua = _config?.userAgent ?? '(MyApp/1.0.0) (Unknown Device; UNKNOWN)';
    final h = <String, String>{
      'User-Agent': ua,
    };
    if (includeJsonAccept) {
      h['Accept'] = 'application/json';
    }
    if (contentTypeJson) {
      h['Content-Type'] = 'application/json';
    }
    return h;
  }

  static String _normalizeBase(String base) => base.replaceAll(RegExp(r'/+$'), '');

  static Map<String, dynamic> _decodeJsonObject(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MyDeeplinkSdkHttpException(res.statusCode, res.body);
    }
    if (res.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
      'Expected JSON object, got ${decoded.runtimeType}',
    );
  }

  /// RN SDK returns `response.data`; keep Flutter consistent with that.
  static Map<String, dynamic> _extractData(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return decoded;
  }
}
