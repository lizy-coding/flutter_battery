package com.example.flutter_battery.ble

data class BleConnectionEvent(
    val state: BleConnectionState,
    val deviceId: String,
    val error: String? = null
) {
    fun toMap(): Map<String, Any?> = hashMapOf(
        "state" to when (state) {
            BleConnectionState.DISCONNECTED -> "disconnected"
            BleConnectionState.CONNECTING -> "connecting"
            BleConnectionState.CONNECTED -> "connected"
            BleConnectionState.DISCONNECTING -> "disconnecting"
        },
        "deviceId" to deviceId,
        "error" to error
    )
}
