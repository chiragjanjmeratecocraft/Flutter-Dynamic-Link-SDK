import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'my_deeplink_sdk_platform_interface.dart';

/// An implementation of [MyDeeplinkSdkPlatform] that uses method channels.
class MethodChannelMyDeeplinkSdk extends MyDeeplinkSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('my_deeplink_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
