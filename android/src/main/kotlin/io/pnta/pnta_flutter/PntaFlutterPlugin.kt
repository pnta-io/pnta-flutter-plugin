package io.pnta.pnta_flutter

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.app.Activity
import io.pnta.pnta_flutter.PermissionHandler
import io.pnta.pnta_flutter.TokenHandler
import io.pnta.pnta_flutter.IdentifyHandler
import io.pnta.pnta_flutter.ForegroundNotificationHandler
import io.pnta.pnta_flutter.NotificationTapHandler

/** PntaFlutterPlugin */
class PntaFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pnta_flutter")
    channel.setMethodCallHandler(this)
    ForegroundNotificationHandler.register(flutterPluginBinding.binaryMessenger)
    NotificationTapHandler.register(flutterPluginBinding.binaryMessenger)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "requestNotificationPermission") {
      PermissionHandler.requestNotificationPermission(activity, result)
    } else if (call.method == "getDeviceToken") {
      TokenHandler.getDeviceToken(activity, result)
    } else if (call.method == "identify") {
      val projectId = call.argument<String>("projectId")
      val deviceToken = call.argument<String>("deviceToken")
      IdentifyHandler.identify(activity, projectId, deviceToken, result)
    } else if (call.method == "setForegroundPresentationOptions") {
      val showSystemUI = call.argument<Boolean>("showSystemUI") ?: false
      ForegroundNotificationHandler.setForegroundPresentationOptions(showSystemUI)
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    return PermissionHandler.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // ActivityAware methods
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
      onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
