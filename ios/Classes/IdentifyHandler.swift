import Foundation
import Flutter
import UIKit

class IdentifyHandler {
    static func identify(projectId: String, metadata: [String: Any]? = nil, result: @escaping FlutterResult) {
        TokenHandler.getDeviceToken { deviceToken in
            guard let token = deviceToken as? String else {
                result(FlutterError(code: "NO_TOKEN", message: "Device token not available", details: nil))
                return
            }
            guard let deviceTokenData = Data(hexString: token) else {
                result(FlutterError(code: "INVALID_TOKEN", message: "Device token is not valid hex", details: nil))
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
                "app_build": bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unavailable"
            ]

            let info: [String: Any] = [
                "project_id": projectId,
                "identifier": token,
                "identifiers": identifiers,
                "metadata": metadata ?? [:]
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

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if nextIndex > hexString.endIndex { return nil }
            let bytes = hexString[index..<nextIndex]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            index = nextIndex
        }
        self = data
    }
} 