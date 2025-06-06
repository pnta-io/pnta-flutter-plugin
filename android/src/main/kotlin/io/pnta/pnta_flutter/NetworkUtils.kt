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
        timeoutMillis: Int = 10000, // 10 seconds
        maxRetries: Int = 3
    ) = withContext(Dispatchers.IO) {
        var lastException: Exception? = null
        var lastResponseCode: Int? = null
        var lastResponseBody: String? = null
        
        repeat(maxRetries) { attempt ->
            try {
                val delayMs = if (attempt > 0) (1000 * 2.0.pow(attempt.toDouble())).toLong() else 0
                if (delayMs > 0) {
                    Log.d("NetworkUtils", "PNTA: Retrying request in ${delayMs}ms (attempt ${attempt + 1}/$maxRetries)")
                    delay(delayMs)
                }
                
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
                
                // Success case
                if (responseCode in 200..299) {
                    withContext(Dispatchers.Main) {
                        result.success(successReturn)
                    }
                    return@withContext
                }
                
                // Check if this error should be retried
                lastResponseCode = responseCode
                lastResponseBody = responseBody
                
                if (!shouldRetry(responseCode) || attempt == maxRetries - 1) {
                    // Don't retry or this was the last attempt
                    withContext(Dispatchers.Main) {
                        Log.e("NetworkUtils", "PNTA: Server returned error: $responseCode. Body: $responseBody")
                        result.error(
                            "HTTP_$responseCode",
                            "Server returned error status code $responseCode",
                            responseBody
                        )
                    }
                    return@withContext
                }
                
                Log.d("NetworkUtils", "PNTA: Server error $responseCode, will retry (attempt ${attempt + 1}/$maxRetries)")
                
            } catch (e: Exception) {
                lastException = e
                
                if (attempt == maxRetries - 1) {
                    // Last attempt failed
                    withContext(Dispatchers.Main) {
                        Log.e("NetworkUtils", "PNTA: Network error after $maxRetries attempts - ${e.localizedMessage}")
                        result.error("NETWORK_ERROR", e.localizedMessage, null)
                    }
                    return@withContext
                }
                
                Log.d("NetworkUtils", "PNTA: Network error, will retry (attempt ${attempt + 1}/$maxRetries): ${e.localizedMessage}")
            }
        }
    }
    
    private fun shouldRetry(responseCode: Int): Boolean {
        return when (responseCode) {
            in 500..599 -> true  // Server errors - retry
            408 -> true          // Request timeout - retry
            429 -> true          // Rate limited - retry
            else -> false        // Client errors (4xx) - don't retry
        }
    }
} 