package com.example.iot.nativekit

data class IotDevice(val id: String, val name: String?, val rssi: Int)

data class TelemetryPayload(
    val deviceId: String,
    val timestamp: Long,
    val metrics: Map<String, Any?>
)

sealed interface IotEvent {
    val deviceId: String?

    data class DeviceDiscovered(override val deviceId: String, val device: IotDevice) : IotEvent
    data class ConnectionState(override val deviceId: String?, val connected: Boolean) : IotEvent
    data class Telemetry(override val deviceId: String, val payload: TelemetryPayload) : IotEvent
    data class Battery(override val deviceId: String?, val level: Int) : IotEvent
}
