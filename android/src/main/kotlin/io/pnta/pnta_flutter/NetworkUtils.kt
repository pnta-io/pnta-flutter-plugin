package io.pnta.pnta_flutter

import android.util.Log
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.pow

object NetworkUtils {
    suspend fun sendPutRequest(
        urlString: String,
        payload: Map<String, Any>,
        result: Result,
        successReturn: Any? = null,
        timeoutMillis: Int = 3000
    ) = withContext(Dispatchers.IO) {
        try {
            val url = URL(urlString)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "PUT"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true
            conn.connectTimeout = timeoutMillis
            conn.readTimeout = timeoutMillis

            val json = JSONObject(payload).toString()

            conn.outputStream.use { outputStream ->
                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(json)
                    writer.flush()
                }
            }

            val responseCode = conn.responseCode
            val responseBody = try {
                conn.inputStream.bufferedReader().use { it.readText() }
            } catch (e: Exception) {
                conn.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
            }
            
            withContext(Dispatchers.Main) {
                if (responseCode in 200..299) {
                    result.success(successReturn)
                } else {
                    result.error(
                        "HTTP_$responseCode",
                        "Server returned error status code $responseCode",
                        responseBody
                    )
                }
            }
        } catch (e: Exception) {
            withContext(Dispatchers.Main) {
                result.error("NETWORK_ERROR", e.localizedMessage, null)
            }
        }
    }
} 