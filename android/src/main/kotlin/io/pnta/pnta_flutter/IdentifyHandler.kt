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
import android.content.Context

object IdentifyHandler {
    /**
     * Identifies the device and sends identification data, including device and app information, to the backend server.
     *
     * Validates the provided project ID, retrieves a device token asynchronously, collects device and app identifiers, and sends all data along with optional metadata to the backend. The result is returned via the provided Flutter `Result` callback, with the device identifier on success or null on failure.
     *
     * @param projectId The unique identifier for the project; must not be null.
     * @param metadata Optional additional data to include in the identification payload.
     */
    fun identify(activity: Activity?, projectId: String?, metadata: Map<String, Any>?, result: Result) {
        if (projectId == null) {
            result.error("INVALID_ARGUMENTS", "projectId is null", null)
            return
        }
        TokenHandler.getDeviceToken(activity, object : Result {
            override fun success(token: Any?) {
                val deviceToken = token as? String
                if (deviceToken == null) {
                    result.error("NO_TOKEN", "Device token not available", null)
                    return
                }
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val identifiers = collectIdentifiers(activity)
                        val info = mapOf(
                            "project_id" to projectId,
                            "identifier" to deviceToken,
                            "identifiers" to identifiers,
                            "metadata" to (metadata ?: mapOf<String, Any>())
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
            override fun error(code: String, message: String?, details: Any?) {
                result.error(code, message, details)
            }
            override fun notImplemented() {
                result.notImplemented()
            }
        })
    }

    /**
     * Collects device and application identifiers for the current Android environment.
     *
     * Gathers information such as device model, system version, Android ID, locale details, currency, timezone, app package name, version, and build number. If any value cannot be determined, "Unavailable" is used as a fallback.
     *
     * @param activity The current Activity, used to access context-dependent identifiers. May be null.
     * @return A map containing device and app identification data.
     */
    private suspend fun collectIdentifiers(activity: Activity?): Map<String, Any> = withContext(Dispatchers.IO) {
        val locale = Locale.getDefault()
        val name = Build.MODEL
        val model = Build.MODEL
        val localizedModel = Build.MODEL
        val systemName = "android"
        val systemVersion = Build.VERSION.RELEASE
        val identifierForVendor = activity?.let {
            Settings.Secure.getString(it.contentResolver, Settings.Secure.ANDROID_ID)
        } ?: "Unavailable"
        val regionCode = locale.country ?: "Unavailable"
        val languageCode = locale.language ?: "Unavailable"
        val currencyCode = try {
            java.util.Currency.getInstance(locale).currencyCode
        } catch (e: Exception) {
            "Unavailable"
        }
        val currentLocale = locale.toString()
        val preferredLanguages = listOf(locale.language)
        val currentTimeZone = TimeZone.getDefault().id
        val bundleIdentifier = activity?.packageName ?: "Unavailable"
        val appVersion = activity?.let {
            try {
                val pInfo = it.packageManager.getPackageInfo(it.packageName, 0)
                pInfo.versionName ?: "Unavailable"
            } catch (e: Exception) {
                "Unavailable"
            }
        } ?: "Unavailable"
        val appBuild = activity?.let {
            try {
                val pInfo = it.packageManager.getPackageInfo(it.packageName, 0)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    pInfo.longVersionCode.toString()
                } else {
                    @Suppress("DEPRECATION")
                    pInfo.versionCode.toString()
                }
            } catch (e: Exception) {
                "Unavailable"
            }
        } ?: "Unavailable"

        mapOf(
            "name" to name,
            "model" to model,
            "localized_model" to localizedModel,
            "system_name" to systemName,
            "system_version" to systemVersion,
            "identifier_for_vendor" to identifierForVendor,
            "region_code" to regionCode,
            "language_code" to languageCode,
            "currency_code" to currencyCode,
            "current_locale" to currentLocale,
            "preferred_languages" to preferredLanguages,
            "current_time_zone" to currentTimeZone,
            "bundle_identifier" to bundleIdentifier,
            "app_version" to appVersion,
            "app_build" to appBuild
        )
    }

    /**
     * Sends identification data to the backend server via an HTTP PUT request.
     *
     * Attempts to transmit the provided info map as JSON to the backend identification endpoint.
     * On a successful response (HTTP 2xx), returns the device identifier via the result callback; otherwise, returns null.
     * Any exceptions during the network operation are logged and result in a null response.
     */
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
                    result.success(info["identifier"])
                } else {
                    Log.e("PNTA", "Identify:Server returned error: $responseCode")
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