package com.example.flutter_battery.core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import com.example.push_notification.PushNotificationManager

/**
 * 电池状态枚举
 */
enum class BatteryState {
    NORMAL,    // 正常状态
    LOW,       // 低电量状态
    CRITICAL,  // 极低电量状态
    CHARGING,  // 充电状态
    FULL       // 已充满状态
}

/**
 * 电池监控管理器
 * 负责监控设备电池电量并在电量低于阈值时触发回调或通知
 */
class BatteryMonitor(private val context: Context) {
    
    // 电池监控相关
    private var batteryLevelThreshold = 20 // 默认电量阈值
    private var useFlutterRendering = false
    private var notificationTitle = "电池电量低"
    private var notificationMessage = "您的电池电量已经低于阈值"
    
    // 低电量回调
    private var onLowBatteryCallback: ((Int) -> Unit)? = null
    
    // 电池电量变化回调
    private var onBatteryLevelChangeCallback: ((Int) -> Unit)? = null
    
    // 电池信息变化回调
    private var onBatteryInfoChangeCallback: ((Map<String, Any>) -> Unit)? = null
    
    // 电量变化监听专用接收器
    private var batteryLevelChangeReceiver: BroadcastReceiver? = null
    
    // 电池状态变化监听接收器
    private var batteryReceiver: BroadcastReceiver? = null
    
    // 上一次电量值，用于过滤相同的电量变化
    private var lastBatteryLevel: Int = -1
    
    // 电池电量推送是否启用防抖动（仅在电量变化时推送）
    private var enableBatteryLevelDebounce: Boolean = true
    
    // 定时器管理器
    private val batteryLevelPushTimer = TimerManager() // 电池电量推送定时器
    private val batteryCheckTimer = TimerManager() // 低电量检查定时器
    private val batteryInfoPushTimer = TimerManager() // 电池信息推送定时器
    
    init {
        // 配置电池电量推送定时器任务
        batteryLevelPushTimer.setTask {
            pushBatteryLevel()
        }
        
        // 配置低电量检查定时器任务
        batteryCheckTimer.setTask {
            checkLowBattery()
        }
        
        // 配置电池信息推送定时器任务
        batteryInfoPushTimer.setTask {
            pushBatteryInfo()
        }
    }
    
    /**
     * 推送电池电量给监听者
     */
    private fun pushBatteryLevel() {
        try {
            val currentLevel = lastBatteryLevel
            if (currentLevel >= 0) { // 确保已经初始化
                if (!enableBatteryLevelDebounce || lastBatteryLevel != currentLevel) {
                    onBatteryLevelChangeCallback?.invoke(currentLevel)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("BatteryMonitor", "Error pushing battery level: ${e.message}")
        }
    }
    
    /**
     * 推送完整电池信息给监听者
     */
    private fun pushBatteryInfo() {
        try {
            val batteryInfo = getBatteryInfo()
            onBatteryInfoChangeCallback?.invoke(batteryInfo)
        } catch (e: Exception) {
            android.util.Log.e("BatteryMonitor", "Error pushing battery info: ${e.message}")
        }
    }
    
    /**
     * 检查低电量并通知
     */
    private fun checkLowBattery() {
        try {
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
        } catch (e: Exception) {
            android.util.Log.e("BatteryMonitor", "Error checking low battery: ${e.message}")
        }
    }
    
    /**
     * 获取电池状态
     * @param level 电池电量百分比
     * @param isCharging 是否在充电
     * @return 电池状态枚举
     */
    private fun getBatteryState(level: Int, isCharging: Boolean): BatteryState {
        return when {
            isCharging && level >= 100 -> BatteryState.FULL
            isCharging -> BatteryState.CHARGING
            level <= batteryLevelThreshold/2 -> BatteryState.CRITICAL
            level <= batteryLevelThreshold -> BatteryState.LOW
            else -> BatteryState.NORMAL
        }
    }
    
    /**
     * 获取电池温度（摄氏度）
     * @return 电池温度
     */
    private fun getBatteryTemperature(): Float {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return temp / 10.0f // 转换为摄氏度
    }
    
    /**
     * 获取电池电压（伏特）
     * @return 电池电压
     */
    private fun getBatteryVoltage(): Float {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        return voltage / 1000.0f // 转换为伏特
    }
    
    /**
     * 判断电池是否在充电
     * @return 是否在充电
     */
    private fun isCharging(): Boolean {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING || 
               status == BatteryManager.BATTERY_STATUS_FULL
    }
    
    /**
     * 获取完整电池信息
     * @return 包含电池信息的Map
     */
    fun getBatteryInfo(): Map<String, Any> {
        val level = getBatteryLevel()
        val charging = isCharging()
        val temperature = getBatteryTemperature()
        val voltage = getBatteryVoltage()
        val state = getBatteryState(level, charging)
        
        return mapOf(
            "level" to level,
            "isCharging" to charging,
            "temperature" to temperature,
            "voltage" to voltage,
            "state" to state.name,
            "timestamp" to System.currentTimeMillis()
        )
    }
    
    /**
     * 获取电池优化建议
     * @return 优化建议列表
     */
    fun getBatteryOptimizationTips(): List<String> {
        val tips = mutableListOf<String>()
        val level = getBatteryLevel()
        val isCharging = isCharging()
        val temperature = getBatteryTemperature()
        
        if (!isCharging && level < 20) {
            tips.add("电量低于20%，建议连接充电器")
        }
        
        if (!isCharging && level < 10) {
            tips.add("电量严重不足，设备可能很快关机")
        }
        
        if (temperature > 40) {
            tips.add("电池温度偏高 (${temperature}°C)，建议避免高强度使用")
        }
        
        if (isCharging && level >= 100) {
            tips.add("电池已充满，可以断开充电器")
        }
        
        return tips
    }
    
    /**
     * 设置电池电量推送间隔
     * @param intervalMs 推送间隔（毫秒）
     * @param enableDebounce 是否启用防抖动
     */
    fun setBatteryLevelPushInterval(intervalMs: Long, enableDebounce: Boolean) {
        enableBatteryLevelDebounce = enableDebounce
        batteryLevelPushTimer.setInterval(intervalMs)
    }
    
    /**
     * 设置电池信息推送间隔
     * @param intervalMs 推送间隔（毫秒）
     */
    fun setBatteryInfoPushInterval(intervalMs: Long) {
        batteryInfoPushTimer.setInterval(intervalMs)
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
     * 设置电池信息变化回调
     */
    fun setOnBatteryInfoChangeCallback(callback: (Map<String, Any>) -> Unit) {
        onBatteryInfoChangeCallback = callback
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
        
        // 启动电池电量推送定时器
        batteryLevelPushTimer.start()
    }
    
    /**
     * 开始监听电池信息变化
     */
    fun startBatteryInfoListening(intervalMs: Long = 5000) {
        // 设置推送间隔
        batteryInfoPushTimer.setInterval(intervalMs)
        
        // 启动电池信息推送定时器
        batteryInfoPushTimer.start()
        
        // 确保电池广播接收器已注册
        registerBatteryReceiver()
    }
    
    /**
     * 停止监听电池信息变化
     */
    fun stopBatteryInfoListening() {
        // 停止推送定时器
        batteryInfoPushTimer.stop()
    }
    
    /**
     * 停止监听电池电量变化
     */
    fun stopBatteryLevelListening() {
        // 停止推送定时器
        batteryLevelPushTimer.stop()
        
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
            batteryCheckTimer.setInterval(intervalMinutes * 60 * 1000L)
            batteryCheckTimer.start()
        }
        
        // 确保电池广播接收器已注册
        registerBatteryReceiver()
    }
    
    /**
     * 停止电池电量监控
     */
    fun stopMonitoring() {
        batteryCheckTimer.stop()
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        synchronized(this) {
            stopMonitoring()
            stopBatteryLevelListening()
            stopBatteryInfoListening()
            unregisterBatteryReceiver()
            
            onLowBatteryCallback = null
            onBatteryLevelChangeCallback = null
            onBatteryInfoChangeCallback = null
            
            batteryLevelPushTimer.dispose()
            batteryCheckTimer.dispose()
            batteryInfoPushTimer.dispose()
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
                        if (batteryPct <= batteryLevelThreshold && !batteryCheckTimer.isRunning()) {
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