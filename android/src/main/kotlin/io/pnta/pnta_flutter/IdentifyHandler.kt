package io.pnta.pnta_flutter

import android.app.Activity
import android.os.Build
import android.provider.Settings
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.TimeZone
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

object IdentifyHandler {
    fun identify(activity: Activity?, projectId: String?, deviceToken: String?, result: Result) {
        if (activity == null || projectId == null || deviceToken == null) {
            result.error("INVALID_ARGUMENTS", "Activity, projectId, or deviceToken is null", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val metadata = collectMetadata(activity, deviceToken)
                val info = mapOf(
                    "project_id" to projectId,
                    "identifier" to deviceToken,
                    "metadata" to metadata
                )
                
                sendToBackend(info, result)
            } catch (e: Exception) {
                Log.e("PNTA", "Error in identify: ${e.localizedMessage}")
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            }
        }
    }

    private suspend fun collectMetadata(activity: Activity, deviceToken: String): Map<String, Any> = withContext(Dispatchers.IO) {
        val packageManager = activity.packageManager
        val packageName = activity.packageName
        val locale = Locale.getDefault()
        
        val appVersion: String = try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            pInfo.versionName ?: "Unavailable"
        } catch (e: Exception) {
            "Unavailable"
        }

        val appBuild: String = try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pInfo.longVersionCode.toString()
            } else {
                @Suppress("DEPRECATION")
                pInfo.versionCode.toString()
            }
        } catch (e: Exception) {
            "Unavailable"
        }

        val currencyCode: String = try {
            java.util.Currency.getInstance(locale).currencyCode
        } catch (e: Exception) {
            "Unavailable"
        }

        val identifierForVendor = Settings.Secure.getString(activity.contentResolver, Settings.Secure.ANDROID_ID) ?: "Unavailable"

        mapOf(
            "name" to Build.MODEL,
            "model" to Build.MODEL,
            "localized_model" to Build.MODEL,
            "system_name" to "android",
            "system_version" to Build.VERSION.RELEASE,
            "identifier_for_vendor" to identifierForVendor,
            "device_token" to deviceToken,
            "region_code" to (locale.country ?: "Unavailable"),
            "language_code" to (locale.language ?: "Unavailable"),
            "currency_code" to currencyCode,
            "current_locale" to locale.toString(),
            "preferred_languages" to listOf(locale.language),
            "current_time_zone" to TimeZone.getDefault().id,
            "bundle_identifier" to packageName,
            "app_version" to appVersion,
            "app_build" to appBuild
        )
    }

    private suspend fun sendToBackend(info: Map<String, Any>, result: Result) = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://app.pnta.io/api/v1/identification")
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