import Foundation
import Flutter

class NetworkUtils {
    static func sendPutRequest(
        urlString: String,
        payload: [String: Any],
        result: @escaping FlutterResult,
        successReturn: Any? = nil
    ) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
            let errorMsg = "[NetworkUtils] PNTA Error: Failed to serialize JSON data for payload: \(payload)"
            print(errorMsg)
            result(FlutterError(code: "JSON_SERIALIZATION_ERROR", message: "Failed to serialize payload to JSON", details: payload))
            return
        }

        guard let url = URL(string: urlString) else {
            let errorMsg = "[NetworkUtils] PNTA Error: Invalid URL: \(urlString)"
            print(errorMsg)
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: urlString))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15 // seconds

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let errorMsg = "[NetworkUtils] PNTA Error: Network error - \(error.localizedDescription)"
                print(errorMsg)
                result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "[NetworkUtils] PNTA Error: No HTTP response received"
                print(errorMsg)
                result(FlutterError(code: "NO_HTTP_RESPONSE", message: "No HTTP response received", details: nil))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                var serverMessage: String? = nil
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    serverMessage = body
                }
                let errorMsg = "[NetworkUtils] PNTA Error: Server returned status code \(httpResponse.statusCode). Body: \(serverMessage ?? "<none>")"
                print(errorMsg)
                result(FlutterError(
                    code: "HTTP_\(httpResponse.statusCode)",
                    message: "Server returned error status code \(httpResponse.statusCode)",
                    details: serverMessage
                ))
                return
            }
            result(successReturn)
        }
        task.resume()
    }
} 