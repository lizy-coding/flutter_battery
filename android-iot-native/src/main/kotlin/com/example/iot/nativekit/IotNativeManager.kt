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

/**
 * IoT 原生管理器
 *
 * 负责设备扫描、连接状态、遥测启动/停止以及电池快照等原生能力的统一入口。
 * 所有接口均为线程安全入口，通过协程在后台执行并通过 SharedFlow 广播事件。
 *
 * 版本兼容性：面向 API v1（METHOD_CHANNEL: iot/native, EVENT_CHANNEL: iot/stream），
 * 事件模型与 Channels 保持一致，调用方可通过事件类型进行区分。
 */
class IotNativeManager(
    private val appContext: Context,
    private val scanner: BleScanner = BleScanner(appContext),
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
) {

    private val _events = MutableSharedFlow<IotEvent>(extraBufferCapacity = 64)
    val events: SharedFlow<IotEvent> = _events.asSharedFlow()

    /**
     * 开始扫描设备
     * @param filters 扫描过滤条件
     */
    fun scanDevices(filters: Map<String, Any?> = emptyMap()) {
        scope.launch {
            scanner.scan(filters) { device ->
                _events.emit(IotEvent.DeviceDiscovered(device.id, device))
            }
        }
    }

    /**
     * 连接指定设备
     * @param deviceId 设备唯一标识
     */
    fun connect(deviceId: String) {
        scope.launch {
            _events.emit(IotEvent.ConnectionState(deviceId, connected = true))
        }
    }

    /**
     * 断开指定设备连接
     * @param deviceId 设备唯一标识
     */
    fun disconnect(deviceId: String) {
        scope.launch {
            _events.emit(IotEvent.ConnectionState(deviceId, connected = false))
        }
    }

    /**
     * 启动设备遥测
     * @param deviceId 设备唯一标识
     * @param metrics 需要采集的指标列表
     */
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

    /**
     * 停止设备遥测
     */
    fun stopTelemetry() {
        TelemetryForegroundService.stop(appContext)
    }

    /**
     * 请求电池快照
     * @param deviceId 可选的设备唯一标识
     */
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

    /**
     * 释放资源
     */
    fun dispose() {
        scope.cancel()
    }
}
