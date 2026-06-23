package io.pnta.pnta_flutter

import android.util.Log
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

object TrackOpenHandler {
    fun trackOpen(projectId: String, notificationId: String, token: String, result: Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val info = mapOf(
                    "project_id" to projectId,
                    "token" to token
                )
                NetworkUtils.sendPutRequest(
                    urlString = "https://app.pnta.io/api/v1/notifications/$notificationId/open",
                    payload = info,
                    result = result
                )
            } catch (e: Exception) {
                Log.e("TrackOpenHandler", "Error in trackOpen: ${e.localizedMessage}")
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            }
        }
    }
}
