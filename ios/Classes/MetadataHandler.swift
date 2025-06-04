import Foundation
import Flutter

class MetadataHandler {
    static func updateMetadata(projectId: String, metadata: [String: Any]? = nil, result: @escaping FlutterResult) {
        TokenHandler.getDeviceToken { deviceToken in
            guard let deviceToken = deviceToken as? String else {
                result(FlutterError(code: "NO_TOKEN", message: "Device token not available", details: nil))
                return
            }
            let info: [String: Any] = [
                "project_id": projectId,
                "identifier": deviceToken,
                "metadata": metadata ?? [:]
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted) else {
                print("PNTA Error: Failed to serialize JSON data")
                result(nil)
                return
            }

            let url = URL(string: "https://app.pnta.io/api/v1/metadata")!
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
} 