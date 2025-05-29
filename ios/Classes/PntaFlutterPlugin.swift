import Flutter
import UIKit
import UserNotifications


public class PntaFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pnta_flutter", binaryMessenger: registrar.messenger())
    let instance = PntaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      PermissionHandler.requestNotificationPermission(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
