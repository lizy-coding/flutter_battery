package com.example.iot.nativekit.data.telemetry

import android.util.Log
import com.example.iot.nativekit.domain.model.Telemetry
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus
import kotlin.math.roundToInt
import kotlin.random.Random

interface TelemetryRepository {
    val telemetryFlow: SharedFlow<Telemetry>
    fun start()
    fun stop()
    fun publish(telemetry: Telemetry)
    fun clear()
}

class TelemetryRepositoryImpl(
    dispatcher: CoroutineDispatcher = Dispatchers.Default
) : TelemetryRepository {

    private val scope = CoroutineScope(SupervisorJob()).plus(dispatcher)
    private val random = Random(System.currentTimeMillis())
    private val _telemetryFlow = MutableSharedFlow<Telemetry>(replay = 1, extraBufferCapacity = 4)
    private var job: Job? = null

    override val telemetryFlow: SharedFlow<Telemetry> = _telemetryFlow.asSharedFlow()

    override fun start() {
        if (job?.isActive == true) return
        job = scope.launch {
            Log.d(TAG, "Start emitting mock telemetry.")
            while (isActive) {
                publish(createMockTelemetry())
                delay(2_000L)
            }
        }
    }

    override fun stop() {
        job?.cancel()
        job = null
    }

    override fun publish(telemetry: Telemetry) {
        if (!_telemetryFlow.tryEmit(telemetry)) {
            scope.launch {
                _telemetryFlow.emit(telemetry)
            }
        }
    }

    override fun clear() {
        stop()
        scope.cancel()
    }

    private fun createMockTelemetry(): Telemetry {
        val baseSpeed = random.nextDouble(12.0, 32.0)
        val battery = random.nextInt(20, 100)
        val rounded = (baseSpeed * 100).roundToInt() / 100.0
        return Telemetry(
            timestamp = System.currentTimeMillis(),
            speed = rounded,
            batteryPct = battery
        )
    }

    companion object {
        private const val TAG = "TelemetryRepository"
    }
}
