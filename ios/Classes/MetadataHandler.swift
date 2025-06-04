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
            NetworkUtils.sendPutRequest(
                urlString: "https://app.pnta.io/api/v1/metadata",
                payload: info,
                result: result
            )
        }
    }
} 