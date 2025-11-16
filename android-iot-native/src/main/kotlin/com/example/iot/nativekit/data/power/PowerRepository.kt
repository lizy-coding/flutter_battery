package com.example.iot.nativekit.data.power

import android.util.Log
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus
import kotlin.random.Random

interface PowerRepository {
    val batteryFlow: StateFlow<Int>
    fun start()
    fun stop()
    fun clear()
}

class PowerRepositoryImpl(
    dispatcher: CoroutineDispatcher = Dispatchers.Default
) : PowerRepository {

    private val scope = CoroutineScope(SupervisorJob()).plus(dispatcher)
    private val random = Random(System.currentTimeMillis())
    private val _batteryFlow = MutableStateFlow(87)
    private var job: Job? = null

    override val batteryFlow: StateFlow<Int> = _batteryFlow

    override fun start() {
        if (job?.isActive == true) return
        job = scope.launch {
            Log.d(TAG, "Start observing mock battery.")
            while (isActive) {
                delay(3_000L)
                val change = random.nextInt(-2, 3)
                val next = (_batteryFlow.value + change).coerceIn(15, 100)
                _batteryFlow.value = next
            }
        }
    }

    override fun stop() {
        job?.cancel()
        job = null
    }

    override fun clear() {
        stop()
        scope.cancel()
    }

    companion object {
        private const val TAG = "PowerRepository"
    }
}
