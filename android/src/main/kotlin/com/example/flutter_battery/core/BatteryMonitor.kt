package com.example.flutter_battery.core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import com.example.push_notification.PushNotificationManager
import java.util.Timer
import java.util.TimerTask

/**
 * 电池监控管理器
 * 负责监控设备电池电量并在电量低于阈值时触发回调或通知
 */
class BatteryMonitor(private val context: Context) {
    
    // 电池监控相关
    private var batteryLevelThreshold = 20 // 默认电量阈值
    private var batteryCheckTimer: Timer? = null
    private var batteryReceiver: BroadcastReceiver? = null
    private var useFlutterRendering = false
    private var notificationTitle = "电池电量低"
    private var notificationMessage = "您的电池电量已经低于阈值"
    
    // 低电量回调
    private var onLowBatteryCallback: ((Int) -> Unit)? = null
    
    // 电池电量变化回调
    private var onBatteryLevelChangeCallback: ((Int) -> Unit)? = null
    
    // 电量变化监听专用接收器
    private var batteryLevelChangeReceiver: BroadcastReceiver? = null
    
    // 上一次电量值，用于过滤相同的电量变化
    private var lastBatteryLevel: Int = -1
    
    // 电池电量推送定时器
    private var batteryLevelPushTimer: Timer? = null
    
    // 电池电量推送间隔（毫秒）
    private var batteryLevelPushIntervalMs: Long = 1000
    
    // 是否启用电量变化防抖动（仅在电量变化时推送）
    private var enableBatteryLevelDebounce: Boolean = true
    
    /**
     * 设置电池电量推送间隔
     * @param intervalMs 推送间隔（毫秒）
     * @param enableDebounce 是否启用防抖动
     */
    fun setBatteryLevelPushInterval(intervalMs: Long, enableDebounce: Boolean) {
        batteryLevelPushIntervalMs = intervalMs
        enableBatteryLevelDebounce = enableDebounce
        
        // 如果当前正在监听，则重新启动推送定时器
        if (batteryLevelChangeReceiver != null) {
            stopBatteryLevelPushTimer()
            startBatteryLevelPushTimer()
        }
    }
    
    /**
     * 设置低电量回调
     */
    fun setOnLowBatteryCallback(callback: (Int) -> Unit) {
        onLowBatteryCallback = callback
    }
    
    /**
     * 设置电池电量变化回调
     */
    fun setOnBatteryLevelChangeCallback(callback: (Int) -> Unit) {
        onBatteryLevelChangeCallback = callback
    }
    
    /**
     * 获取当前电池电量
     * @return 电池电量百分比
     */
    fun getBatteryLevel(): Int {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }
    
    /**
     * 开始监听电池电量变化
     */
    fun startBatteryLevelListening() {
        // 先停止之前的监听
        stopBatteryLevelListening()
        
        // 创建新的广播接收器
        batteryLevelChangeReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                    val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    val batteryPct = (level * 100) / scale
                    
                    // 记录最新的电池电量（供定时器使用）
                    lastBatteryLevel = batteryPct
                }
            }
        }
        
        // 注册广播接收器
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryLevelChangeReceiver, filter)
        
        // 立即获取当前电量
        lastBatteryLevel = getBatteryLevel()
        
        // 启动定时推送电池电量
        startBatteryLevelPushTimer()
    }
    
    /**
     * 启动电池电量推送定时器
     */
    private fun startBatteryLevelPushTimer() {
        // 停止之前的定时器
        stopBatteryLevelPushTimer()
        
        // 创建新的定时器
        batteryLevelPushTimer = Timer()
        batteryLevelPushTimer?.scheduleAtFixedRate(object : TimerTask() {
            private var lastPushedLevel = -1
            
            override fun run() {
                Handler(Looper.getMainLooper()).post {
                    val currentLevel = lastBatteryLevel
                    
                    // 如果启用防抖动，只有在电量变化时才推送
                    if (!enableBatteryLevelDebounce || currentLevel != lastPushedLevel) {
                        lastPushedLevel = currentLevel
                        onBatteryLevelChangeCallback?.invoke(currentLevel)
                    }
                }
            }
        }, 0, batteryLevelPushIntervalMs)
    }
    
    /**
     * 停止电池电量推送定时器
     */
    private fun stopBatteryLevelPushTimer() {
        batteryLevelPushTimer?.cancel()
        batteryLevelPushTimer = null
    }
    
    /**
     * 停止监听电池电量变化
     */
    fun stopBatteryLevelListening() {
        // 停止推送定时器
        stopBatteryLevelPushTimer()
        
        // 注销广播接收器
        batteryLevelChangeReceiver?.let {
            try {
                context.unregisterReceiver(it)
                batteryLevelChangeReceiver = null
            } catch (e: Exception) {
                android.util.Log.e("BatteryMonitor", "Error unregistering battery level change receiver: ${e.message}")
            }
        }
        lastBatteryLevel = -1
    }
    
    /**
     * 启动电池电量监控
     * 
     * @param threshold 电池电量阈值（百分比）
     * @param title 通知标题
     * @param message 通知消息
     * @param intervalMinutes 检查间隔（分钟）
     * @param useFlutterRendering 是否使用Flutter渲染通知
     */
    fun startMonitoring(
        threshold: Int,
        title: String,
        message: String,
        intervalMinutes: Int,
        useFlutterRendering: Boolean
    ) {
        // 设置配置
        batteryLevelThreshold = threshold
        notificationTitle = title
        notificationMessage = message
        this.useFlutterRendering = useFlutterRendering
        
        // 停止之前的定时器
        stopMonitoring()
        
        // 如果间隔大于0，则使用定时器定期检查
        if (intervalMinutes > 0) {
            batteryCheckTimer = Timer()
            batteryCheckTimer?.schedule(
                BatteryCheckTask(),
                0,
                intervalMinutes * 60 * 1000L
            )
        }
        
        // 确保电池广播接收器已注册
        registerBatteryReceiver()
    }
    
    /**
     * 停止电池电量监控
     */
    fun stopMonitoring() {
        batteryCheckTimer?.cancel()
        batteryCheckTimer = null
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        stopMonitoring()
        stopBatteryLevelListening()
        unregisterBatteryReceiver()
        onLowBatteryCallback = null
        onBatteryLevelChangeCallback = null
    }
    
    // 电池监控定时器任务
    private inner class BatteryCheckTask : TimerTask() {
        override fun run() {
            Handler(Looper.getMainLooper()).post {
                val currentLevel = getBatteryLevel()
                if (currentLevel <= batteryLevelThreshold) {
                    if (useFlutterRendering) {
                        // 通知Flutter层处理
                        onLowBatteryCallback?.invoke(currentLevel)
                    } else {
                        // 直接显示系统通知
                        PushNotificationManager.showNotification(
                            context,
                            notificationTitle,
                            "$notificationMessage，当前电量: $currentLevel%"
                        )
                    }
                }
            }
        }
    }
    
    // 注册电池状态变化监听
    private fun registerBatteryReceiver() {
        if (batteryReceiver == null) {
            batteryReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                        val batteryPct = (level * 100) / scale
                        
                        // 如果电量低于阈值并且未使用定时器，检查是否需要发送通知
                        if (batteryPct <= batteryLevelThreshold && batteryCheckTimer == null) {
                            if (useFlutterRendering) {
                                // 通知Flutter层处理
                                onLowBatteryCallback?.invoke(batteryPct)
                            } else {
                                // 直接显示系统通知
                                PushNotificationManager.showNotification(
                                    context,
                                    notificationTitle,
                                    "$notificationMessage，当前电量: $batteryPct%"
                                )
                            }
                        }
                    }
                }
            }
            
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            context.registerReceiver(batteryReceiver, filter)
        }
    }
    
    // 取消注册电池广播接收器
    private fun unregisterBatteryReceiver() {
        batteryReceiver?.let {
            try {
                context.unregisterReceiver(it)
                batteryReceiver = null
            } catch (e: Exception) {
                android.util.Log.e("BatteryMonitor", "Error unregistering battery receiver: ${e.message}")
            }
        }
    }
}