import Foundation
import Flutter

class NotificationTapHandler: NSObject, FlutterStreamHandler {
    static var eventSink: FlutterEventSink?
    static var bufferedPayload: [String: Any]? = nil

    static func register(with registrar: FlutterPluginRegistrar) {
        let eventChannel = FlutterEventChannel(name: "pnta_flutter/notification_tap", binaryMessenger: registrar.messenger())
        let instance = NotificationTapHandler()
        eventChannel.setStreamHandler(instance)
    }

    static func sendTapPayload(_ payload: [String: Any]) {
        if let sink = eventSink {
            sink(payload)
        } else {
            bufferedPayload = payload
        }
    }

    // FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NotificationTapHandler.eventSink = events
        if let payload = NotificationTapHandler.bufferedPayload {
            events(payload)
            NotificationTapHandler.bufferedPayload = nil
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationTapHandler.eventSink = nil
        return nil
    }
} 