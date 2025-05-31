import Flutter
import UIKit
import UserNotifications


public class PntaFlutterPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pnta_flutter", binaryMessenger: registrar.messenger())
    let instance = PntaFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    ForegroundNotificationHandler.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      PermissionHandler.requestNotificationPermission(result: result)
    case "getDeviceToken":
      TokenHandler.getDeviceToken(result: result)
    case "identify":
      if let args = call.arguments as? [String: Any],
         let projectId = args["projectId"] as? String,
         let deviceToken = args["deviceToken"] as? String {
        IdentifyHandler.identify(projectId: projectId, deviceToken: deviceToken, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments for identify", details: nil))
      }
    case "setForegroundPresentationOptions":
      if let args = call.arguments as? [String: Any],
         let showSystemUI = args["showSystemUI"] as? Bool {
        ForegroundNotificationHandler.setForegroundPresentationOptions(showSystemUI: showSystemUI)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing showSystemUI argument", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // UIApplicationDelegate methods for APNs token forwarding
  public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    TokenHandler.didRegisterForRemoteNotifications(deviceToken: deviceToken)
  }

  public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    TokenHandler.didFailToRegisterForRemoteNotifications(error: error)
  }
}
