package io.pnta.pnta_flutter

import android.util.Log
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

object MetadataHandler {
    /**
     * Updates metadata for a given project and device by sending it to the backend server.
     *
     * Initiates retrieval of the device token and, upon success, sends the provided metadata along with the project ID and device token to the backend. If the project ID is null or the device token cannot be obtained, an error is returned via the result callback. All result callbacks are invoked on the main thread.
     */
    fun updateMetadata(projectId: String?, metadata: Map<String, Any>?, result: Result) {
        if (projectId == null) {
            result.error("INVALID_ARGUMENTS", "projectId is null", null)
            return
        }

        // Use TokenHandler to get the device token
        TokenHandler.getDeviceToken(null, object : Result {
            override fun success(token: Any?) {
                val deviceToken = token as? String
                if (deviceToken == null) {
                    result.error("NO_TOKEN", "Device token not available", null)
                    return
                }
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val info = mapOf(
                            "project_id" to projectId,
                            "identifier" to deviceToken,
                            "metadata" to (metadata ?: mapOf<String, Any>())
                        )
                        sendToBackend(info, result)
                    } catch (e: Exception) {
                        Log.e("PNTA", "Error in updateMetadata: ${e.localizedMessage}")
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    }
                }
            }
            override fun error(code: String, message: String?, details: Any?) {
                result.error(code, message, details)
            }
            override fun notImplemented() {
                result.notImplemented()
            }
        })
    }

    /**
     * Sends the provided metadata to the backend server via an HTTP PUT request.
     *
     * Attempts to deliver the given information as a JSON payload to the backend endpoint. Regardless of the HTTP response or any exceptions, the result callback is always invoked on the main thread with a success response containing null.
     */
    private suspend fun sendToBackend(info: Map<String, Any>, result: Result) = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://app.pnta.io/api/v1/metadata")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "PUT"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true

            val json = JSONObject(info).toString()

            conn.outputStream.use { outputStream ->
                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(json)
                    writer.flush()
                }
            }

            val responseCode = conn.responseCode
            withContext(Dispatchers.Main) {
                if (responseCode in 200..299) {
                    result.success(null)
                } else {
                    Log.e("PNTA", "Server returned error: $responseCode")
                    result.success(null)
                }
            }
        } catch (e: Exception) {
            Log.e("PNTA", "Error sending to backend: ${e.localizedMessage}")
            withContext(Dispatchers.Main) {
                result.success(null)
            }
        }
    }
} 