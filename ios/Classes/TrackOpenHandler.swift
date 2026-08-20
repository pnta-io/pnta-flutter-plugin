import Foundation
import Flutter

class TrackOpenHandler {
    static func trackOpen(projectId: String, notificationId: String, token: String, result: @escaping FlutterResult) {
        let info: [String: Any] = [
            "project_id": projectId,
            "token": token
        ]
        NetworkUtils.sendPutRequest(
            urlString: "https://app.pnta.io/api/v1/notifications/\(notificationId)/open",
            payload: info,
            result: result
        )
    }
}
