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
    fun identify(activity: Activity?, projectId: String?, metadata: Map<String, Any>?, pntaSdkVersion: String, result: Result) {
        if (projectId == null) {
            result.error("INVALID_ARGUMENTS", "projectId is null", null)
            return
        }
        TokenHandler.getDeviceToken(activity, object : Result {
            override fun success(token: Any?) {
                val deviceToken = token as? String
                if (deviceToken == null) {
                    result.error("NO_DEVICE_TOKEN", "Device token not available", null)
                    return
                }
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val identifiers = collectIdentifiers(activity, pntaSdkVersion)
                        val info = mapOf(
                            "project_id" to projectId,
                            "identifier" to deviceToken,
                            "identifiers" to identifiers,
                            "metadata" to (metadata ?: mapOf<String, Any>()),
                            "platform" to "android"
                        )
                        NetworkUtils.sendPutRequest(
                            urlString = "https://app.pnta.io/api/v1/identification",
                            payload = info,
                            result = result,
                            successReturn = deviceToken
                        )
                    } catch (e: Exception) {
                        Log.e("IdentifyHandler", "Error in identify: ${e.localizedMessage}")
                        withContext(Dispatchers.Main) {
                            result.error("IDENTIFY_ERROR", "Failed to identify device: ${e.localizedMessage}", e.toString())
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

    private suspend fun collectIdentifiers(activity: Activity?, pntaSdkVersion: String): Map<String, Any> = withContext(Dispatchers.IO) {
        val locale = Locale.getDefault()
        val name = Build.MANUFACTURER
        val model = Build.MODEL
        val localizedModel = Build.MODEL
        val systemName = System.getProperty("os.name") ?: "Android"
        val systemVersion = Build.VERSION.RELEASE
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
            "region_code" to regionCode,
            "language_code" to languageCode,
            "currency_code" to currencyCode,
            "current_locale" to currentLocale,
            "preferred_languages" to preferredLanguages,
            "current_time_zone" to currentTimeZone,
            "bundle_identifier" to bundleIdentifier,
            "app_version" to appVersion,
            "app_build" to appBuild,
            "pnta_sdk_version" to pntaSdkVersion
        )
    }
} 