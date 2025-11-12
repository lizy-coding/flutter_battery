package com.example.iot.nativekit

import android.content.Context
import com.example.iot.nativekit.ble.BleScanner
import com.example.iot.nativekit.service.TelemetryForegroundService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlin.random.Random

class IotNativeManager(
    private val appContext: Context,
    private val scanner: BleScanner = BleScanner(appContext),
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
) {

    private val _events = MutableSharedFlow<IotEvent>(extraBufferCapacity = 64)
    val events: SharedFlow<IotEvent> = _events.asSharedFlow()

    fun scanDevices(filters: Map<String, Any?> = emptyMap()) {
        scope.launch {
            scanner.scan(filters) { device ->
                _events.emit(IotEvent.DeviceDiscovered(device.id, device))
            }
        }
    }

    fun connect(deviceId: String) {
        scope.launch {
            _events.emit(IotEvent.ConnectionState(deviceId, connected = true))
        }
    }

    fun disconnect(deviceId: String) {
        scope.launch {
            _events.emit(IotEvent.ConnectionState(deviceId, connected = false))
        }
    }

    fun startTelemetry(deviceId: String, metrics: List<String> = emptyList()) {
        TelemetryForegroundService.start(appContext)
        scope.launch {
            val payload = TelemetryPayload(
                deviceId = deviceId,
                timestamp = System.currentTimeMillis(),
                metrics = metrics.associateWith { Random.nextDouble(0.0, 100.0) }
            )
            _events.emit(IotEvent.Telemetry(deviceId, payload))
        }
    }

    fun stopTelemetry() {
        TelemetryForegroundService.stop(appContext)
    }

    fun requestBatterySnapshot(deviceId: String?) {
        scope.launch {
            _events.emit(
                IotEvent.Battery(
                    deviceId = deviceId,
                    level = Random.nextInt(15, 100)
                )
            )
        }
    }

    fun dispose() {
        scope.cancel()
    }
}
