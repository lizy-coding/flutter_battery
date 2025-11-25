package com.example.flutter_battery.channel

import android.content.Context
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.TimerManager
import io.flutter.plugin.common.EventChannel
import java.util.HashMap

/**
 * 事件通道处理器
 * 处理Flutter和Android之间的事件流通信，支持控制推送频率
 */
class EventChannelHandler(
    private val context: Context,
    private val eventChannel: EventChannel,
    private val batteryMonitor: BatteryMonitor
) : EventChannel.StreamHandler {
    
    // 事件接收器
    private var eventSink: EventChannel.EventSink? = null
    
    // 定时器管理器
    private val timerManager = TimerManager()
    
    // 电池信息推送定时器
    private val batteryInfoManager = TimerManager()
    private val batteryHealthManager = TimerManager()
    
    // 默认推送间隔（毫秒）
    private var pushIntervalMs: Long = 1000
    
    // 上次推送的电池电量
    private var lastPushedBatteryLevel: Int = -1
    
    // 是否启用防抖动（仅在电量变化时推送）
    private var enableDebounce: Boolean = true
    
    // 是否启用完整电池信息推送
    private var enableBatteryInfoPush: Boolean = false
    private var enableBatteryHealthPush: Boolean = false
    
    /**
     * 初始化
     */
    init {
        // 设置事件处理器
        eventChannel.setStreamHandler(this)
        
        // 配置电池电量定时器任务
        timerManager.setTask { pushBatteryInfo() }
        
        // 配置完整电池信息定时器任务
        batteryInfoManager.setTask { pushCompleteBatteryInfo() }

        // 配置电池健康推送任务
        batteryHealthManager.setTask { pushBatteryHealthInfo() }
    }
    
    /**
     * 设置推送周期
     * @param intervalMs 推送间隔（毫秒）
     * @param enableDebounce 是否启用防抖动（仅在电量变化时推送）
     */
    fun setPushInterval(intervalMs: Long, enableDebounce: Boolean = true) {
        this.pushIntervalMs = intervalMs
        this.enableDebounce = enableDebounce
        
        // 更新定时器间隔
        timerManager.setInterval(intervalMs)
    }
    
    /**
     * 设置电池信息推送
     * @param enable 是否启用
     * @param intervalMs 推送间隔（毫秒）
     */
    fun setBatteryInfoPush(enable: Boolean, intervalMs: Long = 5000) {
        this.enableBatteryInfoPush = enable
        
        if (enable) {
            batteryInfoManager.setInterval(intervalMs)
            
            if (eventSink != null) {
                batteryInfoManager.start()
            }
        } else {
            batteryInfoManager.stop()
        }
    }

    /**
     * 设置电池健康推送
     */
    fun setBatteryHealthPush(enable: Boolean, intervalMs: Long = 10_000) {
        this.enableBatteryHealthPush = enable
        if (enable) {
            batteryHealthManager.setInterval(intervalMs)
            if (eventSink != null) {
                batteryHealthManager.start()
            }
        } else {
            batteryHealthManager.stop()
        }
    }
    
    /**
     * 推送电池简要信息
     */
    private fun pushBatteryInfo() {
        try {
            val currentLevel = batteryMonitor.getBatteryLevel()
            
            // 如果启用防抖动，则只在电量变化时推送
            if (!enableDebounce || currentLevel != lastPushedBatteryLevel) {
                lastPushedBatteryLevel = currentLevel
                
                val batteryInfo = HashMap<String, Any>(2) // 预设容量
                batteryInfo["batteryLevel"] = currentLevel
                batteryInfo["timestamp"] = System.currentTimeMillis()
                
                eventSink?.success(batteryInfo)
            }
        } catch (e: Exception) {
            eventSink?.error(
                "BATTERY_ERROR",
                "获取电池信息失败: ${e.message}",
                e.stackTraceToString()
            )
        }
    }
    
    /**
     * 推送完整电池信息
     */
    private fun pushCompleteBatteryInfo() {
        try {
            val batteryInfo = batteryMonitor.getBatteryInfo()
            
            // 添加消息类型标记
            val message = HashMap<String, Any>(batteryInfo.size + 1)
            message.putAll(batteryInfo)
            message["type"] = "BATTERY_INFO"
            
            eventSink?.success(message)
        } catch (e: Exception) {
            eventSink?.error(
                "BATTERY_INFO_ERROR",
                "获取完整电池信息失败: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun pushBatteryHealthInfo() {
        try {
            val health = batteryMonitor.getBatteryHealth()
            val payload = HashMap<String, Any>(health.size + 1)
            payload.putAll(health)
            payload["type"] = "BATTERY_HEALTH"
            eventSink?.success(payload)
        } catch (e: Exception) {
            eventSink?.error(
                "BATTERY_HEALTH_ERROR",
                "获取电池健康信息失败: ${e.message}",
                e.stackTraceToString()
            )
        }
    }
    
    /**
     * 当监听开始
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // 解析参数（如果有）
        if (arguments is Map<*, *>) {
            val interval = (arguments["pushIntervalMs"] as? Number)?.toLong() ?: pushIntervalMs
            val debounce = (arguments["enableDebounce"] as? Boolean) ?: enableDebounce
            val infoPush = (arguments["enableBatteryInfoPush"] as? Boolean) ?: enableBatteryInfoPush
            val infoInterval = (arguments["batteryInfoIntervalMs"] as? Number)?.toLong() ?: 5000L
            
            setPushInterval(interval, debounce)
            
            if (infoPush) {
                setBatteryInfoPush(true, infoInterval)
            }
        }
        
        // 启动电池电量推送定时器
        timerManager.start()
        
        // 如果启用了电池信息推送，启动对应定时器
        if (enableBatteryInfoPush) {
            batteryInfoManager.start()
        }

        if (enableBatteryHealthPush) {
            batteryHealthManager.start()
        }
    }
    
    /**
     * 当监听取消
     */
    override fun onCancel(arguments: Any?) {
        stopAllTimers()
        eventSink = null
    }
    
    /**
     * 停止所有定时器
     */
    private fun stopAllTimers() {
        timerManager.stop()
        batteryInfoManager.stop()
        batteryHealthManager.stop()
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        synchronized(this) {
            stopAllTimers()
            
            timerManager.dispose()
            batteryInfoManager.dispose()
            batteryHealthManager.dispose()
            
            eventSink = null
            eventChannel.setStreamHandler(null)
        }
    }
} 
