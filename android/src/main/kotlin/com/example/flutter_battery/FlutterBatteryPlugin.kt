package com.example.flutter_battery

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.push_notification.PushNotificationManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.Timer
import java.util.TimerTask

/** FlutterBatteryPlugin */
class FlutterBatteryPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: android.content.Context
    private var activity: android.app.Activity? = null
    
    // 定义权限请求码和回调映射
    private val PERMISSION_REQUEST_CODE = 100
    private var pendingNotificationRequests = mutableListOf<PendingNotificationRequest>()
    
    // 电池监控相关
    private var batteryLevelThreshold = 20 // 默认电量阈值
    private var batteryCheckTimer: Timer? = null
    private var batteryReceiver: BroadcastReceiver? = null
    private var useFlutterRendering = false
    private var notificationTitle = "电池电量低"
    private var notificationMessage = "您的电池电量已经低于阈值"
    
    // 电池监控定时器
    private inner class BatteryCheckTask(
        private val context: Context,
        private val threshold: Int,
        private val title: String,
        private val message: String,
        private val useFlutterRendering: Boolean
    ) : TimerTask() {
        override fun run() {
            Handler(Looper.getMainLooper()).post {
                val currentLevel = getBatteryLevel()
                if (currentLevel <= threshold) {
                    if (useFlutterRendering) {
                        // 通知Flutter层处理
                        val params = HashMap<String, Any>()
                        params["batteryLevel"] = currentLevel
                        channel.invokeMethod("onLowBattery", params)
                    } else {
                        // 直接显示系统通知
                        PushNotificationManager.showNotification(
                            applicationContext,
                            title,
                            "$message，当前电量: $currentLevel%"
                        )
                    }
                }
            }
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        
        // 注册电池状态变化广播接收器
        registerBatteryReceiver()
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
                                val params = HashMap<String, Any>()
                                params["batteryLevel"] = batteryPct
                                channel.invokeMethod("onLowBattery", params)
                            } else {
                                // 直接显示系统通知
                                PushNotificationManager.showNotification(
                                    applicationContext,
                                    notificationTitle,
                                    "$notificationMessage，当前电量: $batteryPct%"
                                )
                            }
                        }
                    }
                }
            }
            
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            applicationContext.registerReceiver(batteryReceiver, filter)
        }
    }
    
    // 取消注册电池广播接收器
    private fun unregisterBatteryReceiver() {
        batteryReceiver?.let {
            try {
                applicationContext.unregisterReceiver(it)
                batteryReceiver = null
            } catch (e: Exception) {
                android.util.Log.e("FlutterBatteryPlugin", "Error unregistering battery receiver: ${e.message}")
            }
        }
    }
    
    // 启动电池电量检查定时器
    private fun startBatteryMonitoring(
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
        stopBatteryMonitoring()
        
        // 如果间隔大于0，则使用定时器定期检查
        if (intervalMinutes > 0) {
            batteryCheckTimer = Timer()
            batteryCheckTimer?.schedule(
                BatteryCheckTask(
                    applicationContext,
                    threshold,
                    title,
                    message,
                    useFlutterRendering
                ),
                0,
                intervalMinutes * 60 * 1000L
            )
        }
        
        // 确保电池广播接收器已注册
        registerBatteryReceiver()
    }
    
    // 停止电池电量检查
    private fun stopBatteryMonitoring() {
        batteryCheckTimer?.cancel()
        batteryCheckTimer = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "getBatteryLevel" -> {
                try {
                    val batteryLevel = getBatteryLevel()
                    result.success(batteryLevel)
                } catch (e: Exception) {
                    result.error("BATTERY_ERROR", "获取电池电量失败: ${e.message}", null)
                }
            }
            "setBatteryLevelThreshold" -> {
                try {
                    val threshold = call.argument<Int>("threshold") ?: 20
                    val title = call.argument<String>("title") ?: "电池电量低"
                    val message = call.argument<String>("message") ?: "您的电池电量已经低于阈值"
                    val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 15
                    val useFlutterRendering = call.argument<Boolean>("useFlutterRendering") ?: false
                    
                    startBatteryMonitoring(
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
                    stopBatteryMonitoring()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("BATTERY_MONITORING_ERROR", "停止电池监控失败: ${e.message}", null)
                }
            }
            "scheduleNotification" -> {
                try {
                    val title = call.argument<String>("title") ?: "通知"
                    val message = call.argument<String>("message") ?: "您有一条新消息"
                    val delayMinutes = call.argument<Int>("delayMinutes") ?: 1
                    
                    // 检查通知权限
                    if (checkNotificationPermission()) {
                        PushNotificationManager.scheduleNotification(
                            applicationContext,
                            title,
                            message,
                            delayMinutes
                        )
                        result.success(true)
                    } else {
                        // 保存请求并请求权限
                        pendingNotificationRequests.add(
                            PendingNotificationRequest(
                                type = NotificationType.SCHEDULED,
                                title = title,
                                message = message,
                                delayMinutes = delayMinutes,
                                result = result
                            )
                        )
                        requestNotificationPermission()
                    }
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
                }
            }
            "showNotification" -> {
                try {
                    val title = call.argument<String>("title") ?: "通知"
                    val message = call.argument<String>("message") ?: "您有一条新消息"
                    
                    // 检查通知权限
                    if (checkNotificationPermission()) {
                        PushNotificationManager.showNotification(
                            applicationContext,
                            title,
                            message
                        )
                        result.success(true)
                    } else {
                        // 保存请求并请求权限
                        pendingNotificationRequests.add(
                            PendingNotificationRequest(
                                type = NotificationType.IMMEDIATE,
                                title = title,
                                message = message,
                                result = result
                            )
                        )
                        requestNotificationPermission()
                    }
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    // 检查通知权限
    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Android 13以下版本不需要运行时权限
        }
    }
    
    // 请求通知权限
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activity != null) {
            ActivityCompat.requestPermissions(
                activity!!,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = applicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopBatteryMonitoring()
        unregisterBatteryReceiver()
    }
    
    // ActivityAware接口实现
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
    
    // 权限请求结果回调
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // 处理挂起的通知请求
                val requests = pendingNotificationRequests.toList()
                pendingNotificationRequests.clear()
                
                for (request in requests) {
                    when (request.type) {
                        NotificationType.IMMEDIATE -> {
                            try {
                                PushNotificationManager.showNotification(
                                    applicationContext,
                                    request.title,
                                    request.message
                                )
                                request.result.success(true)
                            } catch (e: Exception) {
                                request.result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                            }
                        }
                        NotificationType.SCHEDULED -> {
                            try {
                                PushNotificationManager.scheduleNotification(
                                    applicationContext,
                                    request.title,
                                    request.message,
                                    request.delayMinutes ?: 1
                                )
                                request.result.success(true)
                            } catch (e: Exception) {
                                request.result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
                            }
                        }
                    }
                }
                return true
            } else {
                // 权限被拒绝，通知所有挂起的请求
                for (request in pendingNotificationRequests) {
                    request.result.error(
                        "PERMISSION_DENIED",
                        "通知权限被拒绝",
                        null
                    )
                }
                pendingNotificationRequests.clear()
                return true
            }
        }
        return false
    }
    
    // 枚举通知类型
    private enum class NotificationType {
        IMMEDIATE, SCHEDULED
    }
    
    // 挂起的通知请求数据类
    private data class PendingNotificationRequest(
        val type: NotificationType,
        val title: String,
        val message: String,
        val delayMinutes: Int? = null,
        val result: Result
    )
} 