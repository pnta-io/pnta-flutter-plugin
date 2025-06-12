import Foundation
import Flutter
import UIKit

class IdentifyHandler {
    static func identify(projectId: String, metadata: [String: Any]? = nil, pntaSdkVersion: String, result: @escaping FlutterResult) {
        TokenHandler.getDeviceToken { deviceToken in
            guard let token = deviceToken as? String else {
                result(FlutterError(code: "NO_DEVICE_TOKEN", message: "Device token not available", details: nil))
                return
            }
            let device = UIDevice.current
            let locale = Locale.current
            let bundle = Bundle.main

            let identifiers: [String: Any] = [
                "name": device.name,
                "model": device.model,
                "localized_model": device.localizedModel,
                "system_name": "ios",
                "system_version": device.systemVersion,
                "identifier_for_vendor": device.identifierForVendor?.uuidString ?? "Unavailable",
                "region_code": locale.regionCode ?? "Unavailable",
                "language_code": locale.languageCode ?? "Unavailable",
                "currency_code": locale.currencyCode ?? "Unavailable",
                "current_locale": locale.identifier,
                "preferred_languages": Locale.preferredLanguages,
                "current_time_zone": TimeZone.current.identifier,
                "bundle_identifier": bundle.bundleIdentifier ?? "Unavailable",
                "app_version": bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unavailable",
                "app_build": bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unavailable",
                "pnta_sdk_version": pntaSdkVersion
            ]

            let info: [String: Any] = [
                "project_id": projectId,
                "identifier": token,
                "identifiers": identifiers,
                "metadata": metadata ?? [:],
                "platform": "ios"
            ]
            NetworkUtils.sendPutRequest(
                urlString: "https://app.pnta.io/api/v1/identification",
                payload: info,
                result: result,
                successReturn: token
            )
        }
    }
} 