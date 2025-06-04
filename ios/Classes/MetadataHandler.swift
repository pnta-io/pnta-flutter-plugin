import Foundation
import Flutter

class MetadataHandler {
    static func updateMetadata(projectId: String, metadata: [String: Any]? = nil, result: @escaping FlutterResult) {
        TokenHandler.getDeviceToken { deviceToken in
            guard let deviceToken = deviceToken as? String else {
                result(FlutterError(code: "NO_DEVICE_TOKEN", message: "Device token not available", details: nil))
                return
            }
            let info: [String: Any] = [
                "project_id": projectId,
                "identifier": deviceToken,
                "metadata": metadata ?? [:]
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted) else {
                let errorMsg = "PNTA Error: Failed to serialize JSON data for info: \(info)"
                print(errorMsg)
                result(FlutterError(code: "JSON_SERIALIZATION_ERROR", message: "Failed to serialize metadata to JSON", details: info))
                return
            }

            let url = URL(string: "https://app.pnta.io/api/v1/metadata")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    let errorMsg = "PNTA Error: Network error - \(error.localizedDescription)"
                    print(errorMsg)
                    result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    let errorMsg = "PNTA Error: No HTTP response received"
                    print(errorMsg)
                    result(FlutterError(code: "NO_HTTP_RESPONSE", message: "No HTTP response received", details: nil))
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMessage: String? = nil
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        serverMessage = body
                    }
                    let errorMsg = "PNTA Error: Server returned status code \(httpResponse.statusCode). Body: \(serverMessage ?? "<none>")"
                    print(errorMsg)
                    result(FlutterError(
                        code: "HTTP_\(httpResponse.statusCode)",
                        message: "Server returned error status code \(httpResponse.statusCode)",
                        details: serverMessage
                    ))
                    return
                }
                result(nil)
            }
            task.resume()
        }
    }
} 