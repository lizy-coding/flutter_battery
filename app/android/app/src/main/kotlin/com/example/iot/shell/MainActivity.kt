package com.example.iot.shell

import android.os.Bundle
import com.example.iot.nativekit.IotEvent
import com.example.iot.nativekit.IotNativeManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private lateinit var nativeManager: IotNativeManager
    private val scope = CoroutineScope(Dispatchers.Main)
    private var eventsJob: Job? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nativeManager = IotNativeManager(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
        val eventChannel = EventChannel(messenger, EVENT_CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scanDevices" -> {
                    val filters = call.arguments as? Map<String, Any?> ?: emptyMap()
                    nativeManager.scanDevices(filters)
                    result.success(null)
                }
                "connect" -> {
                    val deviceId = call.argument<String>("deviceId")
                    if (deviceId != null) {
                        nativeManager.connect(deviceId)
                        result.success(null)
                    } else {
                        result.error("MISSING_DEVICE", "deviceId is required", null)
                    }
                }
                "startTelemetry" -> {
                    val deviceId = call.argument<String>("deviceId") ?: "demo-device"
                    nativeManager.startTelemetry(deviceId)
                    result.success(null)
                }
                "stopTelemetry" -> {
                    nativeManager.stopTelemetry()
                    result.success(null)
                }
                "requestBatterySnapshot" -> {
                    nativeManager.requestBatterySnapshot(call.argument("deviceId"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                eventsJob = scope.launch {
                    nativeManager.events.collect { event ->
                        events.success(
                            mapOf(
                                "type" to when (event) {
                                    is com.example.iot.nativekit.IotEvent.Telemetry -> "telemetry"
                                    is com.example.iot.nativekit.IotEvent.DeviceDiscovered -> "discovered"
                                    is com.example.iot.nativekit.IotEvent.ConnectionState -> "connection"
                                    is com.example.iot.nativekit.IotEvent.Battery -> "battery"
                                },
                                "deviceId" to event.deviceId,
                                "timestamp" to System.currentTimeMillis(),
                                "data" to when (event) {
                                    is com.example.iot.nativekit.IotEvent.Telemetry -> event.payload.metrics
                                    is com.example.iot.nativekit.IotEvent.DeviceDiscovered -> mapOf(
                                        "name" to event.device.name,
                                        "id" to event.device.id,
                                        "rssi" to event.device.rssi,
                                    )
                                    is com.example.iot.nativekit.IotEvent.ConnectionState ->
                                        mapOf("connected" to event.connected)
                                    is com.example.iot.nativekit.IotEvent.Battery ->
                                        mapOf("level" to event.level)
                                }
                            )
                        )
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventsJob?.cancel()
                eventsJob = null
            }
        })
    }

    override fun onDestroy() {
        eventsJob?.cancel()
        scope.cancel()
        nativeManager.dispose()
        super.onDestroy()
    }

    companion object {
        private const val METHOD_CHANNEL = "iot/native"
        private const val EVENT_CHANNEL = "iot/stream"
    }
}
