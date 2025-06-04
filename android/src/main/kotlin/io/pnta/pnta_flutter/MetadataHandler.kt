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
                        NetworkUtils.sendPutRequest(
                            urlString = "https://app.pnta.io/api/v1/metadata",
                            payload = info,
                            result = result
                        )
                    } catch (e: Exception) {
                        Log.e("MetadataHandler", "Error in updateMetadata: ${e.localizedMessage}")
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
} 