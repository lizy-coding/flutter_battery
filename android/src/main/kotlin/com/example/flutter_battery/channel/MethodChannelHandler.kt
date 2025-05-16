package com.example.flutter_battery.channel

import android.content.Context
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.NotificationHelper
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
    private val notificationHelper: NotificationHelper
) : MethodCallHandler {

    private var activity: android.app.Activity? = null
    
    // 事件通道处理器
    private var eventChannelHandler: EventChannelHandler? = null
    
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
    }

    /**
     * 处理方法调用
     */
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
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
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        activity = null
        eventChannelHandler = null
    }
}