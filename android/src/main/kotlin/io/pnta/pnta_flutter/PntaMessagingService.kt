package io.pnta.pnta_flutter

import android.content.Context
import android.os.Looper
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.app.ActivityManager
import android.os.Handler



class PntaMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        if (isAppInForeground(this)) {
            val data = mutableMapOf<String, Any>()
            remoteMessage.data.forEach { (key, value) ->
                data[key] = value
            }
            remoteMessage.notification?.let {
                data["title"] = it.title ?: ""
                data["body"] = it.body ?: ""
            }
            // Post to main thread for EventChannel
            Handler(Looper.getMainLooper()).post {
                ForegroundNotificationHandler.handleForegroundNotification(this, data)
            }
        }
        // else: let system handle background notifications
    }


    private fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = context.packageName
        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }
} 