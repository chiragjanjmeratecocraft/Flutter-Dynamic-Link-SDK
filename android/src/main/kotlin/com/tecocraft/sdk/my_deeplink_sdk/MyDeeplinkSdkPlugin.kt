package com.tecocraft.sdk.my_deeplink_sdk

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class MyDeeplinkSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {

    private var legacyChannel: MethodChannel? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var initialLink: String? = null

    @Suppress("unused")
    private var initConfig: Map<String, Any>? = null

    private val newIntentListener =
        PluginRegistry.NewIntentListener { intent ->
            intent.data?.toString()?.let { link ->
                eventSink?.success(link)
            }
            false
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger

        legacyChannel = MethodChannel(messenger, "my_deeplink_sdk")
        legacyChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getPlatformVersion") {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            } else {
                result.notImplemented()
            }
        }

        methodChannel = MethodChannel(messenger, "my_deeplink_sdk_methods")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, "my_deeplink_sdk_events")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        legacyChannel?.setMethodCallHandler(null)
        legacyChannel = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(newIntentListener)
        binding.activity.intent?.data?.toString()?.let { initialLink = it }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(newIntentListener)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(newIntentListener)
        binding.activity.intent?.data?.toString()?.let {
            if (initialLink == null) initialLink = it
        }
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(newIntentListener)
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                @Suppress("UNCHECKED_CAST")
                initConfig = call.arguments as? Map<String, Any>
                result.success(null)
            }
            "getInitialLink" -> {
                val link = initialLink ?: activityBinding?.activity?.intent?.data?.toString()
                result.success(link)
            }
            "createShortLink" -> {
                // Wire to your backend (e.g. from Dart with `http`) or implement native HTTP here.
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
