import 'package:flutter_test/flutter_test.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk_platform_interface.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyDeeplinkSdkPlatform
    with MockPlatformInterfaceMixin
    implements MyDeeplinkSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MyDeeplinkSdkPlatform initialPlatform = MyDeeplinkSdkPlatform.instance;

  test('$MethodChannelMyDeeplinkSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMyDeeplinkSdk>());
  });

  test('getPlatformVersion', () async {
    MyDeeplinkSdk myDeeplinkSdkPlugin = MyDeeplinkSdk();
    MockMyDeeplinkSdkPlatform fakePlatform = MockMyDeeplinkSdkPlatform();
    MyDeeplinkSdkPlatform.instance = fakePlatform;

    expect(await myDeeplinkSdkPlugin.getPlatformVersion(), '42');
  });
}
