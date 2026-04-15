class DynamicLinkProject {
  DynamicLinkProject({
    required this.id,
    required this.name,
    required this.description,
    required this.onPlaystore,
    required this.onAppstore,
    required this.androidPackageName,
    required this.iosBundleId,
    required this.defaultUrl,
    required this.androidFallbackUrl,
    required this.iosFallbackUrl,
    this.androidHost,
    this.iosHost,
  });

  final String id;
  final String name;
  final String description;
  final bool onPlaystore;
  final bool onAppstore;
  final String androidPackageName;
  final String? iosBundleId;
  final String defaultUrl;
  final String androidFallbackUrl;
  final String iosFallbackUrl;
  final String? androidHost;
  final String? iosHost;

  factory DynamicLinkProject.fromJson(Map<String, dynamic> json) {
    return DynamicLinkProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      onPlaystore: json['on_playstore'] as bool? ?? false,
      onAppstore: json['on_appstore'] as bool? ?? false,
      androidPackageName: json['android_package_name'] as String? ?? '',
      iosBundleId: json['ios_bundle_id'] as String?,
      defaultUrl: json['default_url'] as String? ?? '',
      androidFallbackUrl: json['android_fallback_url'] as String? ?? '',
      iosFallbackUrl: json['ios_fallback_url'] as String? ?? '',
      androidHost: json['android_host'] as String?,
      iosHost: json['ios_host'] as String?,
    );
  }
}

class DynamicLinkData {
  DynamicLinkData({
    required this.linkId,
    required this.name,
    required this.description,
    required this.shortCode,
    required this.customDomain,
    required this.projectId,
    required this.androidScheme,
    required this.iosScheme,
    required this.desktopLink,
    required this.customData,
    required this.project,
  });

  final String linkId;
  final String name;
  final String description;
  final String shortCode;
  final String? customDomain;
  final String projectId;
  final String androidScheme;
  final String iosScheme;
  final String? desktopLink;
  final Map<String, dynamic> customData;
  final DynamicLinkProject project;

  /// RN compatibility alias: backend currently uses `data` for custom params.
  Map<String, dynamic> get params => customData;

  factory DynamicLinkData.fromJson(Map<String, dynamic> json) {
    final projectJson = json['project'];
    return DynamicLinkData(
      linkId: json['link_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortCode: json['short_code'] as String? ?? '',
      customDomain: json['custom_domain'] as String?,
      projectId: json['projectId'] as String? ?? '',
      androidScheme: json['android_scheme'] as String? ?? '',
      iosScheme: json['ios_scheme'] as String? ?? '',
      desktopLink: json['desktop_link'] as String?,
      customData: _toStringDynamicMap(json['data']),
      project: DynamicLinkProject.fromJson(
        projectJson is Map ? Map<String, dynamic>.from(projectJson) : <String, dynamic>{},
      ),
    );
  }

  static Map<String, dynamic> _toStringDynamicMap(Object? input) {
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return Map<String, dynamic>.from(input);
    return <String, dynamic>{};
  }
}

class DynamicLinkEnvelope {
  DynamicLinkEnvelope({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.success,
  });

  final int statusCode;
  final DynamicLinkData? data;
  final String message;
  final bool success;

  factory DynamicLinkEnvelope.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return DynamicLinkEnvelope(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      data: dataJson is Map ? DynamicLinkData.fromJson(Map<String, dynamic>.from(dataJson)) : null,
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }
}
