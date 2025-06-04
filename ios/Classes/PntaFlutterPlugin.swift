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

  /// Handles method calls from the Flutter side for notification permissions, device token retrieval, user identification, metadata updates, and foreground notification presentation options.
  ///
  /// Supported method calls:
  /// - `"requestNotificationPermission"`: Requests notification permissions from the user.
  /// - `"getDeviceToken"`: Retrieves the device's push notification token.
  /// - `"identify"`: Identifies the user with a project ID and optional metadata.
  /// - `"updateMetadata"`: Updates user metadata for a given project ID.
  /// - `"setForegroundPresentationOptions"`: Sets whether system UI is shown for foreground notifications.
  ///
  /// Returns results or errors to the Flutter side via the provided result callback. If required arguments are missing, returns a Flutter error with code `"INVALID_ARGUMENTS"`. For unrecognized methods, returns `FlutterMethodNotImplemented`.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      PermissionHandler.requestNotificationPermission(result: result)
    case "getDeviceToken":
      TokenHandler.getDeviceToken(result: result)
    case "identify":
      if let args = call.arguments as? [String: Any],
         let projectId = args["projectId"] as? String {
        let metadata = args["metadata"] as? [String: Any]
        IdentifyHandler.identify(projectId: projectId, metadata: metadata, result: result)
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
