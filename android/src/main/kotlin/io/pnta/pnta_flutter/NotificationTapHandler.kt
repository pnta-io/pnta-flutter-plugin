package io.pnta.pnta_flutter

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.BinaryMessenger

object NotificationTapHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var bufferedPayload: Map<String, Any>? = null

    fun register(messenger: BinaryMessenger) {
        val eventChannel = EventChannel(messenger, "pnta_flutter/notification_tap")
        eventChannel.setStreamHandler(this)
    }

    fun sendTapPayload(payload: Map<String, Any>) {
        if (eventSink != null) {
            eventSink?.success(payload)
        } else {
            bufferedPayload = payload
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        bufferedPayload?.let {
            events?.success(it)
            bufferedPayload = null
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
} 