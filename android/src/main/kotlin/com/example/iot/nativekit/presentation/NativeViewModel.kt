package com.example.iot.nativekit.presentation

import android.content.Context
import android.util.Log
import com.example.iot.nativekit.data.ble.BleRepository
import com.example.iot.nativekit.data.power.PowerRepository
import com.example.iot.nativekit.data.telemetry.TelemetryRepository
import com.example.iot.nativekit.domain.model.Device
import com.example.iot.nativekit.domain.model.Telemetry
import com.example.iot.nativekit.service.SyncService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.plus

class NativeViewModel(
    private val bleRepository: BleRepository,
    private val telemetryRepository: TelemetryRepository,
    private val powerRepository: PowerRepository,
) {

    private val scope = CoroutineScope(SupervisorJob()).plus(Dispatchers.Main.immediate)

    val devicesFlow: Flow<List<Device>> = bleRepository.devicesFlow
    val telemetryFlow: SharedFlow<Telemetry> = telemetryRepository.telemetryFlow
    val batteryFlow: StateFlow<Int> = powerRepository.batteryFlow

    init {
        telemetryRepository.start()
        powerRepository.start()
    }

    fun startScan() {
        runCatching { bleRepository.startScan() }
            .onFailure { Log.w(TAG, "startScan failed", it) }
    }

    fun stopScan() {
        runCatching { bleRepository.stopScan() }
            .onFailure { Log.w(TAG, "stopScan failed", it) }
    }

    fun connect(deviceId: String) {
        runCatching { bleRepository.connect(deviceId) }
            .onFailure { Log.w(TAG, "connect failed", it) }
    }

    fun disconnect() {
        runCatching { bleRepository.disconnect() }
            .onFailure { Log.w(TAG, "disconnect failed", it) }
    }

    fun startSyncService(context: Context) {
        runCatching { SyncService.start(context) }
            .onFailure { Log.w(TAG, "startSyncService failed", it) }
    }

    fun stopSyncService(context: Context) {
        runCatching { SyncService.stop(context) }
            .onFailure { Log.w(TAG, "stopSyncService failed", it) }
    }

    fun clear() {
        scope.cancel()
        bleRepository.clear()
        telemetryRepository.clear()
        powerRepository.clear()
    }

    companion object {
        private const val TAG = "NativeViewModel"
    }
}
