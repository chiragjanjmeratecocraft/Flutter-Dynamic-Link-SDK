/// Thrown when a backend request completes with a non-success HTTP status.
class MyDeeplinkSdkHttpException implements Exception {
  MyDeeplinkSdkHttpException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'MyDeeplinkSdkHttpException($statusCode): ${body.isEmpty ? '(empty body)' : body}';
}

/// Thrown when the backend returns a 200 OK but with no pending link for this device.
/// This is a normal, expected case (e.g. user opened the app directly, not from a link).
/// The caller should silently ignore this exception — it is NOT an error.
class MyDeeplinkSdkNoPendingLinkException implements Exception {
  const MyDeeplinkSdkNoPendingLinkException();

  @override
  String toString() => 'MyDeeplinkSdkNoPendingLinkException: No pending link found for this device.';
}
