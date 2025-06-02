package io.pnta.pnta_flutter_example

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.pnta.pnta_flutter.NotificationTapHandler

class MainActivity: FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val extras = intent.extras
        if (extras != null && !extras.isEmpty) {
            val payload = mutableMapOf<String, Any>()
            for (key in extras.keySet()) {
                val value = extras.get(key)
                when (value) {
                    is String, is Int, is Boolean, is Double, is Float, is Long -> payload[key] = value
                    else -> payload[key] = value.toString()
                }
            }
            if (payload.isNotEmpty()) {
                NotificationTapHandler.sendTapPayload(payload)
            }
        }
    }
}
