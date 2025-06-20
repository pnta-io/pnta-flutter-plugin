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
    NotificationTapHandler.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      PermissionHandler.requestNotificationPermission(result: result)
    case "checkNotificationPermission":
      PermissionHandler.checkNotificationPermission(result: result)
    case "getDeviceToken":
      TokenHandler.getDeviceToken(result: result)
    case "identify":
      if let args = call.arguments as? [String: Any],
         let projectId = args["projectId"] as? String {
        let pntaSdkVersion = args["pntaSdkVersion"] as? String ?? "Unknown"
        IdentifyHandler.identify(projectId: projectId, pntaSdkVersion: pntaSdkVersion, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments for identify", details: nil))
      }
    case "updateMetadata":
      if let args = call.arguments as? [String: Any],
         let projectId = args["projectId"] as? String {
        let metadata = args["metadata"] as? [String: Any]
        MetadataHandler.updateMetadata(projectId: projectId, metadata: metadata, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments for updateMetadata", details: nil))
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
