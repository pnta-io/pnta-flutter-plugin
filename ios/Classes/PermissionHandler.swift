import Foundation
import UserNotifications
import Flutter

class PermissionHandler {
    static func requestNotificationPermission(result: @escaping FlutterResult) {
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
    }
} 