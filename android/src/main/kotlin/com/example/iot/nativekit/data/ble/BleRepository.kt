package com.example.iot.nativekit.data.ble

import android.util.Log
import com.example.iot.nativekit.domain.model.Device
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus
import kotlin.random.Random

interface BleRepository {
    val devicesFlow: Flow<List<Device>>
    fun startScan()
    fun stopScan()
    fun connect(deviceId: String)
    fun disconnect()
    fun clear()
}

class BleRepositoryImpl(
    dispatcher: CoroutineDispatcher = Dispatchers.Default
) : BleRepository {

    private val scope = CoroutineScope(SupervisorJob()).plus(dispatcher)
    private val scanning = MutableStateFlow(false)
    private val connectedDevice = MutableStateFlow<String?>(null)
    private val random = Random(System.currentTimeMillis())

    override val devicesFlow: Flow<List<Device>> = callbackFlow {
        val job = scope.launch {
            scanning.collectLatest { active ->
                if (!active) {
                    Log.d(TAG, "Stop scanning, clearing devices.")
                    trySend(emptyList()).isSuccess
                    return@collectLatest
                }
                Log.d(TAG, "Start scanning mock devices.")
                while (isActive && scanning.value) {
                    val devices = buildMockDevices()
                    trySend(devices).isSuccess
                    delay(SCAN_INTERVAL_MS)
                }
            }
        }
        awaitClose { job.cancel() }
    }

    override fun startScan() {
        scanning.value = true
    }

    override fun stopScan() {
        scanning.value = false
    }

    override fun connect(deviceId: String) {
        connectedDevice.value = deviceId
        Log.d(TAG, "Mock connect to $deviceId")
    }

    override fun disconnect() {
        Log.d(TAG, "Mock disconnect from ${connectedDevice.value}")
        connectedDevice.value = null
    }

    override fun clear() {
        scanning.value = false
        scope.cancel()
    }

    private fun buildMockDevices(): List<Device> {
        val connected = connectedDevice.value
        return MOCK_DEVICES.map { device ->
            device.copy(
                rssi = random.nextInt(-90, -35),
                connected = device.id == connected
            )
        }.shuffled(random)
    }

    companion object {
        private const val SCAN_INTERVAL_MS = 2_000L

        private val MOCK_DEVICES = listOf(
            Device("sensor-001", "Pump Room Sensor", -55, false),
            Device("sensor-002", "HVAC Gateway", -62, false),
            Device("sensor-003", "Battery Pack", -70, false)
        )

        private const val TAG = "BleRepository"
    }
}
