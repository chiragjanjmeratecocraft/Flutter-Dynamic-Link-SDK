class TestUrlItem {
  TestUrlItem({
    required this.id,
    required this.title,
    required this.url,
    required this.notes,
  });

  final String id;
  final String title;
  final String url;
  final String notes;

  factory TestUrlItem.fromJson(Map<String, dynamic> json) {
    return TestUrlItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class DeeplinkTestConfig {
  DeeplinkTestConfig({
    required this.meta,
    required this.sdkInit,
    required this.sampleShortCode,
    required this.sampleApiResponseShape,
    required this.testUrls,
    required this.adb,
  });

  final Map<String, dynamic> meta;
  final Map<String, dynamic> sdkInit;
  final String sampleShortCode;
  final Map<String, dynamic>? sampleApiResponseShape;
  final List<TestUrlItem> testUrls;
  final Map<String, String> adb;

  factory DeeplinkTestConfig.fromJson(Map<String, dynamic> json) {
    final urls = json['test_urls'] as List<dynamic>? ?? [];
    final adbRaw = json['adb'] as Map<String, dynamic>? ?? {};
    return DeeplinkTestConfig(
      meta: Map<String, dynamic>.from(json['meta'] as Map? ?? {}),
      sdkInit: Map<String, dynamic>.from(json['sdk_init'] as Map? ?? {}),
      sampleShortCode: json['sample_short_code'] as String? ?? '',
      sampleApiResponseShape: json['sample_api_response_shape'] is Map
          ? Map<String, dynamic>.from(json['sample_api_response_shape'] as Map)
          : null,
      testUrls: urls
          .map((e) => TestUrlItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      adb: adbRaw.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}
