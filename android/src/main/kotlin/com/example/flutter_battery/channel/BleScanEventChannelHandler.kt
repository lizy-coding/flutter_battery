package com.example.flutter_battery.channel

import com.example.flutter_battery.ble.BleDevice
import com.example.flutter_battery.ble.BleManager
import io.flutter.plugin.common.EventChannel

class BleScanEventChannelHandler(
    private val bleManager: BleManager
) : EventChannel.StreamHandler, BleManager.ScanListener {

    private var events: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        this.events = events
        bleManager.setScanListener(this)
    }

    override fun onCancel(arguments: Any?) {
        bleManager.setScanListener(null)
        events = null
    }

    override fun onDeviceFound(device: BleDevice) {
        events?.success(listOf(device.toMap()))
    }

    override fun onScanError(message: String) {
        events?.error("SCAN_ERROR", message, null)
    }
}
