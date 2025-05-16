package com.example.flutter_battery.channel

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.flutter_battery.core.BatteryMonitor
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask

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
    
    // 推送定时器
    private var pushTimer: Timer? = null
    
    // 默认推送间隔（毫秒）
    private var pushIntervalMs: Long = 1000
    
    // 上次推送的电池电量
    private var lastPushedBatteryLevel: Int = -1
    
    // 是否启用防抖动（仅在电量变化时推送）
    private var enableDebounce: Boolean = true
    
    /**
     * 初始化
     */
    init {
        // 设置事件处理器
        eventChannel.setStreamHandler(this)
    }
    
    /**
     * 设置推送周期
     * @param intervalMs 推送间隔（毫秒）
     * @param enableDebounce 是否启用防抖动（仅在电量变化时推送）
     */
    fun setPushInterval(intervalMs: Long, enableDebounce: Boolean = true) {
        this.pushIntervalMs = intervalMs
        this.enableDebounce = enableDebounce
        
        // 如果定时器已启动，重启定时器应用新的间隔
        if (pushTimer != null) {
            stopPushTimer()
            startPushTimer()
        }
    }
    
    /**
     * 开始推送定时器
     */
    private fun startPushTimer() {
        // 停止之前的定时器
        stopPushTimer()
        
        // 创建新的定时器
        pushTimer = Timer()
        pushTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                Handler(Looper.getMainLooper()).post {
                    pushBatteryInfo()
                }
            }
        }, 0, pushIntervalMs)
    }
    
    /**
     * 停止推送定时器
     */
    private fun stopPushTimer() {
        pushTimer?.cancel()
        pushTimer = null
    }
    
    /**
     * 推送电池信息
     */
    private fun pushBatteryInfo() {
        val currentLevel = batteryMonitor.getBatteryLevel()
        
        // 如果启用防抖动，则只在电量变化时推送
        if (!enableDebounce || currentLevel != lastPushedBatteryLevel) {
            lastPushedBatteryLevel = currentLevel
            
            val batteryInfo = HashMap<String, Any>()
            batteryInfo["batteryLevel"] = currentLevel
            batteryInfo["timestamp"] = System.currentTimeMillis()
            
            eventSink?.success(batteryInfo)
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
            setPushInterval(interval, debounce)
        }
        
        // 启动推送定时器
        startPushTimer()
    }
    
    /**
     * 当监听取消
     */
    override fun onCancel(arguments: Any?) {
        stopPushTimer()
        eventSink = null
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        stopPushTimer()
        eventSink = null
        eventChannel.setStreamHandler(null)
    }
} 