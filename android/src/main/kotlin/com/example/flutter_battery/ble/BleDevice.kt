package com.example.flutter_battery.ble

data class BleDevice(
    val id: String,
    val name: String,
    val rssi: Int
) {
    fun toMap(): Map<String, Any?> = hashMapOf(
        "id" to id,
        "name" to name,
        "rssi" to rssi
    )
}
