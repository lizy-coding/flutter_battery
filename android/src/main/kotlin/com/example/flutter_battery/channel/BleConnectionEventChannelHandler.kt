package com.example.flutter_battery.channel

import com.example.flutter_battery.ble.BleConnectionEvent
import com.example.flutter_battery.ble.BleManager
import io.flutter.plugin.common.EventChannel

class BleConnectionEventChannelHandler(
    private val bleManager: BleManager
) : EventChannel.StreamHandler, BleManager.ConnectionListener {

    private var events: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        this.events = events
        bleManager.setConnectionListener(this)
    }

    override fun onCancel(arguments: Any?) {
        bleManager.setConnectionListener(null)
        events = null
    }

    override fun onConnectionEvent(event: BleConnectionEvent) {
        events?.success(event.toMap())
    }
}
