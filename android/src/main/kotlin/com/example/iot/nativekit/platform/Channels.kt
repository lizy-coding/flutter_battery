package com.example.iot.nativekit.platform

import android.content.Context
import android.util.Log
import com.example.iot.nativekit.domain.model.toMap
import com.example.iot.nativekit.presentation.NativeViewModel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus

/**
 * Flutter <-> IoT 原生通信通道
 *
 * MethodChannel: `iot/native`，提供设备扫描/连接与同步服务控制；
 * EventChannel: `iot/stream`，推送 devices/telemetry/battery 三类事件。
 *
 * 线程模型：在主线程收集流并安全分发事件，内部使用协程 Job 管理订阅生命周期。
 */
class Channels(
    private val appContext: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val scope = CoroutineScope(SupervisorJob()).plus(Dispatchers.Main.immediate)
    private var devicesJob: Job? = null
    private var telemetryJob: Job? = null
    private var batteryJob: Job? = null
    private var sink: SafeEventSink? = null
    @Volatile
    private var viewModel: NativeViewModel? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun setViewModel(vm: NativeViewModel) {
        viewModel = vm
        restartStreams()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val vm = viewModel
        if (vm == null) {
            result.error("not_ready", "IoT warmup not completed", null)
            return
        }
        when (call.method) {
            "scanDevices" -> {
                vm.startScan()
                result.success(null)
            }
            "stopScan" -> {
                vm.stopScan()
                result.success(null)
            }
            "connect" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId.isNullOrBlank()) {
                    result.error("invalid_args", "deviceId is required", null)
                } else {
                    vm.connect(deviceId)
                    result.success(null)
                }
            }
            "disconnect" -> {
                vm.disconnect()
                result.success(null)
            }
            "startSync" -> {
                vm.startSyncService(appContext)
                result.success(null)
            }
            "stopSync" -> {
                vm.stopSyncService(appContext)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        onCancel(null)
        sink = SafeEventSink(events)
        restartStreams()
    }

    override fun onCancel(arguments: Any?) {
        cancelJobs()
        sink = null
    }

    fun dispose() {
        onCancel(null)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }

    private fun restartStreams() {
        cancelJobs()
        val vm = viewModel ?: return
        val targetSink = sink ?: return
        devicesJob = scope.launch {
            vm.devicesFlow.collectLatest { devices ->
                targetSink.success(mapOf("type" to "devices", "payload" to devices.map { it.toMap() }))
            }
        }
        telemetryJob = scope.launch {
            vm.telemetryFlow.collectLatest { telemetry ->
                targetSink.success(mapOf("type" to "telemetry", "payload" to telemetry.toMap()))
            }
        }
        batteryJob = scope.launch {
            vm.batteryFlow.collectLatest { pct ->
                targetSink.success(mapOf("type" to "battery", "payload" to mapOf("value" to pct)))
            }
        }
    }

    private fun cancelJobs() {
        devicesJob?.cancel()
        telemetryJob?.cancel()
        batteryJob?.cancel()
        devicesJob = null
        telemetryJob = null
        batteryJob = null
    }

    private class SafeEventSink(
        private val delegate: EventChannel.EventSink?
    ) {
        fun success(payload: Any?) {
            runCatching { delegate?.success(payload) }
                .onFailure { Log.w(TAG, "Failed to dispatch event.", it) }
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "iot/native"
        private const val EVENT_CHANNEL = "iot/stream"
        private const val TAG = "NativeChannels"
    }
}
