import Flutter
import UIKit
import UserNotifications

public class PntaFlutterPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pnta_flutter", binaryMessenger: registrar.messenger())
    let instance = PntaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      PermissionHandler.requestNotificationPermission(result: result)
    case "getDeviceToken":
      TokenHandler.getDeviceToken(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // UIApplicationDelegate methods for APNs token forwarding
  public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("PntaFlutterPlugin: didRegisterForRemoteNotificationsWithDeviceToken called")
    TokenHandler.didRegisterForRemoteNotifications(deviceToken: deviceToken)
  }

  public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("PntaFlutterPlugin: didFailToRegisterForRemoteNotificationsWithError called")
    TokenHandler.didFailToRegisterForRemoteNotifications(error: error)
  }
}
