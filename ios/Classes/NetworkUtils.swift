import Foundation
import Flutter

class NetworkUtils {
    static func sendPutRequest(
        urlString: String,
        payload: [String: Any],
        result: @escaping FlutterResult,
        successReturn: Any? = nil
    ) {
        let jsonData = try! JSONSerialization.data(withJSONObject: payload, options: [])
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 3

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    result(FlutterError(code: "NO_HTTP_RESPONSE", message: "No HTTP response received", details: nil))
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    result(successReturn)
                } else {
                    let serverMessage = data != nil ? String(data: data!, encoding: .utf8) : nil
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
} 