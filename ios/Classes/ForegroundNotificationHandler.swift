import Foundation
import Flutter
import UserNotifications

class ForegroundNotificationHandler: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate, FlutterStreamHandler {
    static var showSystemUI: Bool = false
    static var eventSink: FlutterEventSink?

    static func register(with registrar: FlutterPluginRegistrar) {
        let eventChannel = FlutterEventChannel(name: "pnta_flutter/foreground_notifications", binaryMessenger: registrar.messenger())
        let instance = ForegroundNotificationHandler()
        eventChannel.setStreamHandler(instance)
        UNUserNotificationCenter.current().delegate = instance
    }

    // FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        ForegroundNotificationHandler.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        ForegroundNotificationHandler.eventSink = nil
        return nil
    }

    // Set the showSystemUI flag from Flutter
    static func setForegroundPresentationOptions(showSystemUI: Bool) {
        ForegroundNotificationHandler.showSystemUI = showSystemUI
    }

    // UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Flatten the payload to match Android structure
        var flattenedData: [String: Any] = [:]
        
        // Add all custom data (everything except "aps")
        for (key, value) in userInfo where key != "aps" {
            flattenedData[key] = value
        }
        
        // Extract title/body from aps.alert
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any] {
            flattenedData["title"] = alert["title"] ?? ""
            flattenedData["body"] = alert["body"] ?? ""
        }
        
        // Forward flattened payload to Dart
        ForegroundNotificationHandler.eventSink?(flattenedData)
        // Show or suppress system UI
        if ForegroundNotificationHandler.showSystemUI {
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        } else {
            completionHandler([])
        }
    }

    // Handle notification tap events
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let stringKeyedUserInfo = userInfo.reduce(into: [String: Any]()) { (dict, pair) in
            if let key = pair.key as? String {
                dict[key] = pair.value
            }
        }
        NotificationTapHandler.sendTapPayload(stringKeyedUserInfo)
        completionHandler()
    }
} 