package io.pnta.pnta_flutter

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.MethodChannel.Result
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.FirebaseApp

object TokenHandler {
    fun getDeviceToken(activity: Activity?, result: Result) {
        // Use application context from activity if available, otherwise from FirebaseApp
        val context: Context? = activity?.applicationContext ?: try {
            FirebaseApp.getInstance().applicationContext
        } catch (e: Exception) {
            null
        }
        if (context == null) {
            result.error("NO_CONTEXT", "Unable to obtain application context", null)
            return
        }
        // Ensure Firebase is initialized
        if (FirebaseApp.getApps(context).isEmpty()) {
            FirebaseApp.initializeApp(context)
        }
        FirebaseMessaging.getInstance().token
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    result.success(task.result)
                } else {
                    result.error("FCM_TOKEN_ERROR", task.exception?.localizedMessage, null)
                }
            }
    }
} 