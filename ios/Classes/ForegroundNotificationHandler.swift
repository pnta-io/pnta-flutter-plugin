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
        // Forward payload to Dart
        ForegroundNotificationHandler.eventSink?(userInfo)
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
} 