package com.example.flutter_battery.channel

import com.example.flutter_battery.ble.PeerState
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper

class PeerEventChannelHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendPeerState(state: PeerState) {
        val sink = eventSink ?: return
        mainHandler.post {
            sink.success(state.toMap())
        }
    }
}
