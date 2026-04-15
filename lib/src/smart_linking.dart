import 'models.dart';

typedef OnSmartLinkSuccess = void Function(DynamicLinkData data);
typedef OnSmartLinkError = void Function(Object error, StackTrace stackTrace);
typedef OnSmartLinkUrl = void Function(String url);

class SmartLinkingOptions {
  const SmartLinkingOptions({
    this.onSuccess,
    this.onError,
    this.onUrl,
  });

  final OnSmartLinkSuccess? onSuccess;
  final OnSmartLinkError? onError;
  final OnSmartLinkUrl? onUrl;
}

