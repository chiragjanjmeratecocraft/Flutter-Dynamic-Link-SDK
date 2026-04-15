import Flutter
import UIKit

public class MyDeeplinkSdkPlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var initialLink: String?

  private var initConfig: [String: Any]?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MyDeeplinkSdkPlugin()
    registrar.addApplicationDelegate(instance)

    let legacy = FlutterMethodChannel(name: "my_deeplink_sdk", binaryMessenger: registrar.messenger())
    legacy.setMethodCallHandler { call, result in
      if call.method == "getPlatformVersion" {
        result("iOS " + UIDevice.current.systemVersion)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let methods = FlutterMethodChannel(name: "my_deeplink_sdk_methods", binaryMessenger: registrar.messenger())
    methods.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }

    let events = FlutterEventChannel(name: "my_deeplink_sdk_events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      initConfig = call.arguments as? [String: Any]
      result(nil)
    case "getInitialLink":
      result(initialLink)
    case "createShortLink":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      if initialLink == nil {
        initialLink = url.absoluteString
      }
    }
    return true
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let link = url.absoluteString
    if initialLink == nil {
      initialLink = link
    }
    eventSink?(link)
    return true
  }

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
      return false
    }
    let link = url.absoluteString
    if initialLink == nil {
      initialLink = link
    }
    eventSink?(link)
    return true
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
