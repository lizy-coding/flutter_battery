package com.example.iot.nativekit.domain.model

data class Device(
    val id: String,
    val name: String?,
    val rssi: Int?,
    val connected: Boolean
)

fun Device.toMap(): Map<String, Any?> = mapOf(
    "id" to id,
    "name" to name,
    "rssi" to rssi,
    "connected" to connected
)
