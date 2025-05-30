package io.pnta.pnta_flutter

import android.app.Activity
import io.flutter.plugin.common.MethodChannel.Result
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.FirebaseApp

object TokenHandler {
    fun getDeviceToken(activity: Activity?, result: Result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        // Ensure Firebase is initialized
        if (FirebaseApp.getApps(activity.applicationContext).isEmpty()) {
            FirebaseApp.initializeApp(activity.applicationContext)
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