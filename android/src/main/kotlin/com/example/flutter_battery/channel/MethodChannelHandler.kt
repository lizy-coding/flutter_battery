package com.example.flutter_battery.channel

import android.content.Context
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.flutter_battery.ble.BleConstants
import com.example.flutter_battery.ble.GattClientManager
import com.example.flutter_battery.ble.GattServerManager
import com.example.flutter_battery.ble.PeerState
import com.example.flutter_battery.ble.PeerStateListener
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.NotificationHelper
import com.example.flutter_battery.ble.BleManager
import com.example.push_notification.PushNotificationManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * 方法通道处理器
 * 处理Flutter和Android之间的方法调用
 */
class MethodChannelHandler(
    private val context: Context,
    private val channel: MethodChannel,
    private val batteryMonitor: BatteryMonitor,
    private val notificationHelper: NotificationHelper,
    @Suppress("unused") private val pushNotificationManager: PushNotificationManager,
    private val bleManager: BleManager,
    private val gattServerManager: GattServerManager,
    private val gattClientManager: GattClientManager
) : MethodCallHandler, PeerStateListener {

    private var activity: android.app.Activity? = null

    // 事件通道处理器
    private var eventChannelHandler: EventChannelHandler? = null
    private var peerEventChannelHandler: PeerEventChannelHandler? = null

    private val blePermissions = listOfNotNull(
        android.Manifest.permission.BLUETOOTH_SCAN,
        android.Manifest.permission.BLUETOOTH_CONNECT,
        android.Manifest.permission.BLUETOOTH_ADVERTISE,
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) android.Manifest.permission.ACCESS_FINE_LOCATION else null
    )

    /**
     * 设置当前活动
     */
    fun setActivity(activity: android.app.Activity?) {
        this.activity = activity
    }

    /**
     * 设置事件通道处理器
     */
    fun setEventChannelHandler(handler: EventChannelHandler) {
        eventChannelHandler = handler
    }

    fun setPeerEventChannelHandler(handler: PeerEventChannelHandler) {
        peerEventChannelHandler = handler
    }

    /**
     * 初始化
     */
    init {
        // 设置低电量回调
        batteryMonitor.setOnLowBatteryCallback { batteryLevel ->
            val params = HashMap<String, Any>()
            params["batteryLevel"] = batteryLevel
            channel.invokeMethod("onLowBattery", params)
        }

        // 设置电池电量变化回调
        batteryMonitor.setOnBatteryLevelChangeCallback { batteryLevel ->
            val params = HashMap<String, Any>()
            params["batteryLevel"] = batteryLevel
            channel.invokeMethod("onBatteryLevelChanged", params)
        }

        // 设置电池信息变化回调
        batteryMonitor.setOnBatteryInfoChangeCallback { batteryInfo ->
            channel.invokeMethod("onBatteryInfoChanged", batteryInfo)
        }

        batteryMonitor.setOnBatteryHealthChangeCallback { batteryHealth ->
            channel.invokeMethod("onBatteryHealthChanged", batteryHealth)
        }

        gattServerManager.setPeerStateListener(this)
        gattClientManager.setPeerStateListener(this)
    }

    /**
     * 处理方法调用
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isBleAvailable" -> result.success(bleManager.isBleAvailable())
                "isBleEnabled" -> result.success(bleManager.isBleEnabled())
                "startScan" -> {
                    if (!ensureBlePermissions(result)) return
                    val args = call.arguments as? Map<*, *>
                    val serviceUuid = args?.get("serviceUuid") as? String
                    bleManager.startScan(serviceUuid)
                    result.success(null)
                }
                "stopScan" -> {
                    bleManager.stopScan()
                    result.success(null)
                }
                "connect" -> {
                    if (!ensureBlePermissions(result)) return
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    val autoConnect = (args?.get("autoConnect") as? Boolean) ?: false
                    if (deviceId == null) {
                        result.error("INVALID_ARGS", "deviceId is required", null)
                    } else {
                        bleManager.connect(deviceId, autoConnect)
                        result.success(null)
                    }
                }
                "disconnect" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    bleManager.disconnect(deviceId)
                    result.success(null)
                }
                "writeCharacteristic" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    val serviceUuid = args?.get("serviceUuid") as? String
                    val characteristicUuid = args?.get("characteristicUuid") as? String
                    @Suppress("UNCHECKED_CAST")
                    val valueList = args?.get("value") as? List<Number>
                    val withResponse = (args?.get("withResponse") as? Boolean) ?: true

                    if (deviceId == null || serviceUuid == null || characteristicUuid == null || valueList == null) {
                        result.error("INVALID_ARGS", "deviceId, serviceUuid, characteristicUuid, value are required", null)
                    } else {
                        val byteArray = ByteArray(valueList.size) { i -> valueList[i].toByte() }
                        val success = bleManager.writeCharacteristic(
                            deviceId = deviceId,
                            serviceUuid = serviceUuid,
                            characteristicUuid = characteristicUuid,
                            value = byteArray,
                            withResponse = withResponse
                        )
                        result.success(success)
                    }
                }
                "startSlaveMode" -> {
                    if (!ensureBlePermissions(result)) return
                    gattClientManager.stopMasterMode()
                    gattServerManager.startSlaveMode()
                    result.success(null)
                }
                "stopSlaveMode" -> {
                    gattServerManager.stopSlaveMode()
                    result.success(null)
                }
                "startMasterMode" -> {
                    if (!ensureBlePermissions(result)) return
                    gattServerManager.stopSlaveMode()
                    gattClientManager.startMasterMode()
                    result.success(null)
                }
                "stopMasterMode" -> {
                    gattClientManager.stopMasterMode()
                    result.success(null)
                }
                "masterConnectToDevice" -> {
                    val args = call.arguments as? Map<*, *>
                    val deviceId = args?.get("deviceId") as? String
                    if (deviceId.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "deviceId is required", null)
                    } else {
                        gattClientManager.connectToSlave(deviceId)
                        result.success(null)
                    }
                }
                "stopAllPeerModes" -> {
                    gattClientManager.stopMasterMode()
                    gattServerManager.stopSlaveMode()
                    result.success(null)
                }
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                "getBatteryLevel" -> {
                    try {
                        val batteryLevel = batteryMonitor.getBatteryLevel()
                        result.success(batteryLevel)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "获取电池电量失败: ${e.message}", null)
                    }
                }
                "getBatteryInfo" -> {
                    try {
                        val batteryInfo = batteryMonitor.getBatteryInfo()
                        result.success(batteryInfo)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "获取电池信息失败: ${e.message}", null)
                    }
                }
                "getBatteryHealth" -> {
                    try {
                        val batteryHealth = batteryMonitor.getBatteryHealth()
                        result.success(batteryHealth)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "获取电池健康失败: ${e.message}", null)
                    }
                }
                "getBatteryOptimizationTips" -> {
                    try {
                        val tips = batteryMonitor.getBatteryOptimizationTips()
                        result.success(tips)
                    } catch (e: Exception) {
                        result.error("BATTERY_TIPS_ERROR", "获取电池优化建议失败: ${e.message}", null)
                    }
                }
                "startBatteryLevelListening" -> {
                    try {
                        batteryMonitor.startBatteryLevelListening()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "开始电池电量监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryLevelListening" -> {
                    try {
                        batteryMonitor.stopBatteryLevelListening()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "停止电池电量监听失败: ${e.message}", null)
                    }
                }
                "startBatteryInfoListening" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong() ?: 5000
                        batteryMonitor.startBatteryInfoListening(intervalMs)

                        // 启用事件通道完整电池信息推送
                        eventChannelHandler?.setBatteryInfoPush(true, intervalMs)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "开始电池信息监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryInfoListening" -> {
                    try {
                        batteryMonitor.stopBatteryInfoListening()

                        // 禁用事件通道完整电池信息推送
                        eventChannelHandler?.setBatteryInfoPush(false)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_INFO_ERROR", "停止电池信息监听失败: ${e.message}", null)
                    }
                }
                "startBatteryHealthListening" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong()
                            ?: 10_000L
                        batteryMonitor.startBatteryHealthListening(intervalMs)
                        eventChannelHandler?.setBatteryHealthPush(true, intervalMs)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "开始电池健康监听失败: ${e.message}", null)
                    }
                }
                "stopBatteryHealthListening" -> {
                    try {
                        batteryMonitor.stopBatteryHealthListening()
                        eventChannelHandler?.setBatteryHealthPush(false)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_HEALTH_ERROR", "停止电池健康监听失败: ${e.message}", null)
                    }
                }
                "setBatteryLevelThreshold" -> {
                    try {
                        val threshold = call.argument<Int>("threshold") ?: 20
                        val title = call.argument<String>("title") ?: "电池电量低"
                        val message = call.argument<String>("message") ?: "您的电池电量已经低于阈值"
                        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 15
                        val useFlutterRendering = call.argument<Boolean>("useFlutterRendering") ?: false

                        batteryMonitor.startMonitoring(
                            threshold,
                            title,
                            message,
                            intervalMinutes,
                            useFlutterRendering
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_MONITORING_ERROR", "设置电池监控失败: ${e.message}", null)
                    }
                }
                "stopBatteryMonitoring" -> {
                    try {
                        batteryMonitor.stopMonitoring()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_MONITORING_ERROR", "停止电池监控失败: ${e.message}", null)
                    }
                }
                "setPushInterval" -> {
                    try {
                        val intervalMs = call.argument<Number>("intervalMs")?.toLong() ?: 1000
                        val enableDebounce = call.argument<Boolean>("enableDebounce") ?: true

                        // 同时设置两种推送间隔：EventChannel和BatteryMonitor
                        // 1. 更新 EventChannel 推送频率
                        eventChannelHandler?.setPushInterval(intervalMs, enableDebounce)

                        // 2. 更新 BatteryMonitor 推送频率
                        batteryMonitor.setBatteryLevelPushInterval(intervalMs, enableDebounce)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EVENT_CHANNEL_ERROR", "设置推送间隔失败: ${e.message}", null)
                    }
                }
                "scheduleNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "通知"
                        val message = call.argument<String>("message") ?: "您有一条新消息"
                        val delayMinutes = call.argument<Int>("delayMinutes") ?: 1

                        notificationHelper.scheduleNotification(
                            title,
                            message,
                            delayMinutes,
                            activity,
                            result
                        )
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
                    }
                }
                "showNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "通知"
                        val message = call.argument<String>("message") ?: "您有一条新消息"

                        notificationHelper.showNotification(
                            title,
                            message,
                            activity,
                            result
                        )
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("UNKNOWN_ERROR", "处理方法调用时发生未知错误: ${e.message}", e.stackTraceToString())
        }
    }

    /**
     * 清理资源
     */
    fun dispose() {
        synchronized(this) {
            activity = null
            eventChannelHandler = null
            peerEventChannelHandler = null
            gattClientManager.stopMasterMode()
            gattServerManager.stopSlaveMode()
        }
    }

    override fun onPeerState(state: PeerState) {
        peerEventChannelHandler?.sendPeerState(state)
    }

    private fun ensureBlePermissions(result: Result): Boolean {
        val missing = blePermissions.filter {
            ContextCompat.checkSelfPermission(context, it) != android.content.pm.PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            return true
        }
        val currentActivity = activity
        if (currentActivity != null) {
            ActivityCompat.requestPermissions(currentActivity, missing.toTypedArray(), BLE_PERMISSION_REQUEST_CODE)
            result.error(
                "PERMISSION_REQUIRED",
                "已发起蓝牙权限申请，请在系统弹窗中授权后重试。",
                null
            )
        } else {
            result.error(
                "PERMISSION_DENIED",
                "缺少蓝牙权限，且当前无活动用于请求权限。",
                null
            )
        }
        return false
    }

    companion object {
        private const val BLE_PERMISSION_REQUEST_CODE = 0xB10
    }
}
