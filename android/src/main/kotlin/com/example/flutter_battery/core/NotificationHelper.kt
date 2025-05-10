package com.example.flutter_battery.core

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.push_notification.PushNotificationManager
import io.flutter.plugin.common.MethodChannel.Result as MethodResult

/**
 * 通知辅助工具类
 * 封装通知权限请求和显示通知的相关逻辑
 */
class NotificationHelper(
    private val context: Context
) {
    companion object {
        const val PERMISSION_REQUEST_CODE = 100
    }
    
    // 挂起的通知请求列表
    private val pendingNotificationRequests = mutableListOf<PendingNotificationRequest>()
    
    // 权限结果监听器
    private var permissionResultListener: ((requestCode: Int, permissions: Array<out String>, grantResults: IntArray) -> Boolean)? = null
    
    /**
     * 设置权限结果监听器
     */
    fun setPermissionResultListener(listener: (requestCode: Int, permissions: Array<out String>, grantResults: IntArray) -> Boolean) {
        permissionResultListener = listener
    }
    
    /**
     * 检查通知权限
     * @return 是否已授予通知权限
     */
    fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Android 13以下版本不需要运行时权限
        }
    }
    
    /**
     * 请求通知权限
     * @param activity 当前活动
     */
    fun requestNotificationPermission(activity: Activity?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activity != null) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                PERMISSION_REQUEST_CODE
            )
        }
    }
    
    /**
     * 显示通知
     * @param title 通知标题
     * @param message 通知内容
     * @param activity 当前活动（用于请求权限）
     * @param result Flutter结果回调
     */
    fun showNotification(
        title: String,
        message: String,
        activity: Activity?,
        result: MethodResult
    ) {
        if (checkNotificationPermission()) {
            try {
                PushNotificationManager.showNotification(
                    context,
                    title,
                    message
                )
                result.success(true)
            } catch (e: Exception) {
                result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
            }
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
            requestNotificationPermission(activity)
        }
    }
    
    /**
     * 调度延迟通知
     * @param title 通知标题
     * @param message 通知内容
     * @param delayMinutes 延迟分钟数
     * @param activity 当前活动（用于请求权限）
     * @param result Flutter结果回调
     */
    fun scheduleNotification(
        title: String,
        message: String,
        delayMinutes: Int,
        activity: Activity?,
        result: MethodResult
    ) {
        if (checkNotificationPermission()) {
            try {
                PushNotificationManager.scheduleNotification(
                    context,
                    title,
                    message,
                    delayMinutes
                )
                result.success(true)
            } catch (e: Exception) {
                result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
            }
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
            requestNotificationPermission(activity)
        }
    }
    
    /**
     * 处理权限请求结果
     * @param requestCode 请求码
     * @param permissions 权限
     * @param grantResults 授权结果
     * @return 是否已处理
     */
    fun handleRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
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
                                    context,
                                    request.title,
                                    request.message
                                )
                                request.result.success(true)
                            } catch (e: Exception) {
                                Log.e("NotificationHelper", "无法显示通知: ${e.message}")
                                request.result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                            }
                        }
                        NotificationType.SCHEDULED -> {
                            try {
                                PushNotificationManager.scheduleNotification(
                                    context,
                                    request.title,
                                    request.message,
                                    request.delayMinutes ?: 1
                                )
                                request.result.success(true)
                            } catch (e: Exception) {
                                Log.e("NotificationHelper", "无法调度通知: ${e.message}")
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
    
    /**
     * 清理资源
     */
    fun dispose() {
        permissionResultListener = null
        pendingNotificationRequests.clear()
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
        val result: MethodResult
    )
}