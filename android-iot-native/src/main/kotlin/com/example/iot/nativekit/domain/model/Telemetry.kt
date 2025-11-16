package com.example.iot.nativekit.domain.model

data class Telemetry(
    val timestamp: Long,
    val speed: Double,
    val batteryPct: Int
)

fun Telemetry.toMap(): Map<String, Any> = mapOf(
    "timestamp" to timestamp,
    "speed" to speed,
    "batteryPct" to batteryPct
)
