import Foundation
import Flutter
import UIKit

class IdentifyHandler {
    static func identify(projectId: String, deviceToken: String, result: @escaping FlutterResult) {
        guard let deviceTokenData = Data(hexString: deviceToken) else {
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
            "identifier": deviceToken,
            "identifiers": identifiers,
            "metadata": [:]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted) else {
            print("PNTA Error: Failed to serialize JSON data")
            result(nil)
            return
        }

        let url = URL(string: "https://app.pnta.io/api/v1/identification")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("PNTA Error: \(error.localizedDescription)")
                result(nil)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("PNTA Error: Server returned an error")
                result(nil)
                return
            }
            result(nil)
        }
        task.resume()
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