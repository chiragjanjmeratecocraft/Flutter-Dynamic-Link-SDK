/// Thrown when a backend request completes with a non-success HTTP status.
class MyDeeplinkSdkHttpException implements Exception {
  MyDeeplinkSdkHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'MyDeeplinkSdkHttpException($statusCode): ${body.isEmpty ? '(empty body)' : body}';
}
