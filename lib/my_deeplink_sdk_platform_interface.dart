import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'my_deeplink_sdk_method_channel.dart';

abstract class MyDeeplinkSdkPlatform extends PlatformInterface {
  /// Constructs a MyDeeplinkSdkPlatform.
  MyDeeplinkSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static MyDeeplinkSdkPlatform _instance = MethodChannelMyDeeplinkSdk();

  /// The default instance of [MyDeeplinkSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelMyDeeplinkSdk].
  static MyDeeplinkSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MyDeeplinkSdkPlatform] when
  /// they register themselves.
  static set instance(MyDeeplinkSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
