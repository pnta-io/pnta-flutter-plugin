import Foundation
import Flutter
import UIKit

class TokenHandler {
    private static var deviceToken: String?
    private static var pendingResult: FlutterResult?

    static func getDeviceToken(result: @escaping FlutterResult) {
        if let token = deviceToken {
            result(token)
        } else {
            pendingResult = result
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    static func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        if let result = pendingResult {
            result(token)
            pendingResult = nil
        }
    }

    static func didFailToRegisterForRemoteNotifications(error: Error) {
        if let result = pendingResult {
            result(FlutterError(code: "APNS_REGISTRATION_FAILED", message: error.localizedDescription, details: nil))
            pendingResult = nil
        }
    }
} 