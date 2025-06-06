import Foundation
import Flutter

class NetworkUtils {
    static func sendPutRequest(
        urlString: String,
        payload: [String: Any],
        result: @escaping FlutterResult,
        successReturn: Any? = nil,
        maxRetries: Int = 3
    ) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            let errorMsg = "[NetworkUtils] PNTA Error: Failed to serialize JSON data for payload: \(payload)"
            print(errorMsg)
            result(FlutterError(code: "JSON_SERIALIZATION_ERROR", message: "Failed to serialize payload to JSON", details: payload))
            return
        }

        guard let url = URL(string: urlString) else {
            let errorMsg = "PNTA: Invalid URL: \(urlString)"
            print(errorMsg)
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: urlString))
            return
        }

        attemptRequest(url: url, jsonData: jsonData, attempt: 1, maxRetries: maxRetries, result: result, successReturn: successReturn)
    }
    
    private static func attemptRequest(
        url: URL,
        jsonData: Data,
        attempt: Int,
        maxRetries: Int,
        result: @escaping FlutterResult,
        successReturn: Any?
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15 // seconds

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt - 1))
                    print("PNTA: Network error, will retry in \(delay)s (attempt \(attempt)/\(maxRetries)): \(error.localizedDescription)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        attemptRequest(url: url, jsonData: jsonData, attempt: attempt + 1, maxRetries: maxRetries, result: result, successReturn: successReturn)
                    }
                    return
                } else {
                    let errorMsg = "PNTA: Network error after \(maxRetries) attempts - \(error.localizedDescription)"
                    print(errorMsg)
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                    }
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "PNTA: No HTTP response received"
                print(errorMsg)
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_HTTP_RESPONSE", message: "No HTTP response received", details: nil))
                }
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    result(successReturn)
                }
                return
            }
            
            // Handle HTTP errors
            var serverMessage: String?
            if let data = data, let body = String(data: data, encoding: .utf8) {
                serverMessage = body
            }
            
            if shouldRetry(statusCode: httpResponse.statusCode) && attempt < maxRetries {
                let delay = pow(2.0, Double(attempt - 1))
                print("PNTA: Server error \(httpResponse.statusCode), will retry in \(delay)s (attempt \(attempt)/\(maxRetries))")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    attemptRequest(url: url, jsonData: jsonData, attempt: attempt + 1, maxRetries: maxRetries, result: result, successReturn: successReturn)
                }
            } else {
                let errorMsg = "PNTA: Server returned error: \(httpResponse.statusCode). Body: \(serverMessage ?? "<none>")"
                print(errorMsg)
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "HTTP_\(httpResponse.statusCode)",
                        message: "Server returned error status code \(httpResponse.statusCode)",
                        details: serverMessage
                    ))
                }
            }
        }
        task.resume()
    }
    
    private static func shouldRetry(statusCode: Int) -> Bool {
        switch statusCode {
        case 500...599: return true  // Server errors - retry
        case 408: return true        // Request timeout - retry
        case 429: return true        // Rate limited - retry
        default: return false        // Client errors (4xx) - don't retry
        }
    }
} 