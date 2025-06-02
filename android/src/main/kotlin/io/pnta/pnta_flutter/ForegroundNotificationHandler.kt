package io.pnta.pnta_flutter

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.BinaryMessenger

object ForegroundNotificationHandler : EventChannel.StreamHandler {
    private var showSystemUI: Boolean = false
    private var eventSink: EventChannel.EventSink? = null
    private const val CHANNEL_ID = "pnta_default"

    fun register(messenger: BinaryMessenger) {
        val eventChannel = EventChannel(messenger, "pnta_flutter/foreground_notifications")
        eventChannel.setStreamHandler(this)
    }

    fun setForegroundPresentationOptions(showSystemUI: Boolean) {
        this.showSystemUI = showSystemUI
    }

    fun handleForegroundNotification(context: Context, data: Map<String, Any>) {
        // Forward payload to Dart
        eventSink?.success(data)
        // Show system notification if requested
        if (showSystemUI) {
            showSystemNotification(context, data)
        }
    }

    private fun showSystemNotification(context: Context, data: Map<String, Any>) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "General Notifications", NotificationManager.IMPORTANCE_DEFAULT)
            notificationManager.createNotificationChannel(channel)
        }
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(data["title"] as? String ?: "Notification")
            .setContentText(data["body"] as? String ?: "")
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
        // Optionally add more fields from data
        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
} 