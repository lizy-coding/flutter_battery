package com.example.iot.nativekit.ble

import android.content.Context
import com.example.iot.nativekit.IotDevice
import kotlinx.coroutines.delay

class BleScanner(private val context: Context) {
    suspend fun scan(
        filters: Map<String, Any?> = emptyMap(),
        onDevice: suspend (IotDevice) -> Unit
    ) {
        delay(250)
        onDevice(IotDevice(id = "demo-device", name = "IoT Demo", rssi = -60))
    }
}
