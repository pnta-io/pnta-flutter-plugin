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
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import android.content.Intent

/** PntaFlutterPlugin */
class PntaFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var pluginBinding: ActivityPluginBinding? = null

  private fun createDefaultNotificationChannel(context: Context) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channelId = "pnta_default"
      val channelName = "General Notifications"
      val importance = NotificationManager.IMPORTANCE_DEFAULT
      val channel = NotificationChannel(channelId, channelName, importance)
      val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      notificationManager.createNotificationChannel(channel)
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pnta_flutter")
    channel.setMethodCallHandler(this)
    
    ForegroundNotificationHandler.register(flutterPluginBinding.binaryMessenger)
    NotificationTapHandler.register(flutterPluginBinding.binaryMessenger)
    // Create default notification channel on engine attach
    createDefaultNotificationChannel(flutterPluginBinding.applicationContext)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "requestNotificationPermission") {
      PermissionHandler.requestNotificationPermission(activity, result)
    } else if (call.method == "getDeviceToken") {
      TokenHandler.getDeviceToken(activity, result)
    } else if (call.method == "identify") {
      val projectId = call.argument<String>("projectId")
      val metadata = call.argument<Map<String, Any>>("metadata")
      val pntaSdkVersion = call.argument<String>("pntaSdkVersion") ?: "Unknown"
      if (projectId == null) {
        result.error("INVALID_ARGUMENTS", "projectId is null", null)
        return
      }
      IdentifyHandler.identify(activity, projectId, metadata, pntaSdkVersion, result)
    } else if (call.method == "updateMetadata") {
      val projectId = call.argument<String>("projectId")
      val metadata = call.argument<Map<String, Any>>("metadata")
      if (projectId == null) {
        result.error("INVALID_ARGUMENTS", "projectId is null", null)
        return
      }
      MetadataHandler.updateMetadata(projectId, metadata, result)
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
    pluginBinding = binding
    binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
      onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    pluginBinding?.removeOnNewIntentListener(this)
    pluginBinding = null
    PermissionHandler.cleanup()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    pluginBinding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
    pluginBinding?.removeOnNewIntentListener(this)
    pluginBinding = null
    PermissionHandler.cleanup()
  }

  override fun onNewIntent(intent: Intent): Boolean {
    val extras = intent.extras
    if (extras != null && !extras.isEmpty) {
      val payload = mutableMapOf<String, Any>()
      for (key in extras.keySet()) {
        val value = extras.get(key)
        when (value) {
          is String, is Int, is Boolean, is Double, is Float, is Long -> payload[key] = value
          else -> if (value != null) payload[key] = value.toString()
        }
      }
      if (payload.isNotEmpty()) {
        NotificationTapHandler.sendTapPayload(payload)
      }
    }
    return false // allow other listeners to process
  }
}
