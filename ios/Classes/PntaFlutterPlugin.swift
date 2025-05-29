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
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "requestNotificationPermission":
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
          DispatchQueue.main.async {
            result(granted)
          }
        }
      } else {
        // For iOS versions below 10, permissions are granted at app install time
        result(true)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
