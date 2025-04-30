package com.example.flutter_battery

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
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

/** FlutterBatteryPlugin */
class FlutterBatteryPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: android.content.Context
    private var activity: android.app.Activity? = null
    
    // 定义权限请求码和回调映射
    private val PERMISSION_REQUEST_CODE = 100
    private var pendingNotificationRequests = mutableListOf<PendingNotificationRequest>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
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
        val batteryManager = applicationContext.getSystemService(android.content.Context.BATTERY_SERVICE) as android.os.BatteryManager
        return batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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