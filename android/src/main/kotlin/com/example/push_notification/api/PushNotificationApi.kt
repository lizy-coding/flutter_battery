package com.example.push_notification.api

import android.content.Context
import android.content.Intent
import com.example.push_notification.PushNotificationInitializer
import com.example.push_notification.PushNotificationManager

/**
 * 推送通知模块对外API
 * 提供类似image_analysis和biometric_auth模块的入口点
 */
object PushNotificationApi {

    /**
     * 初始化推送通知模块
     * 在应用启动时调用
     *
     * @param context 应用上下文
     */
    fun initialize(context: Context) {
        PushNotificationInitializer.initialize(context.applicationContext)
    }

    /**
     * 立即发送一条推送通知
     *
     * @param context 上下文
     * @param title 通知标题
     * @param message 通知内容
     */
    fun sendNotification(context: Context, title: String, message: String) {
        // 确保模块已初始化
        initialize(context)
        
        // 直接显示通知
        PushNotificationManager.showNotification(
            context = context,
            title = title,
            message = message
        )
    }

    /**
     * 设置延迟推送通知
     *
     * @param context 上下文
     * @param title 通知标题
     * @param message 通知内容
     * @param delayMinutes 延迟分钟数
     */
    fun scheduleNotification(
        context: Context,
        title: String,
        message: String,
        delayMinutes: Int = -1
    ) {
        if (delayMinutes <= 0) {
            sendNotification(
                context = context,
                title = title,
                message = message
            )
        }
        // 确保模块已初始化
        initialize(context)
        
        // 调度延迟通知
        PushNotificationManager.scheduleNotification(
            context = context,
            title = title,
            message = message,
            delayMinutes = delayMinutes
        )
    }

    /**
     * 启动通知设置界面
     *
     * @param context 启动上下文
     */
    fun startNotificationSettingsActivity(context: Context) {
        // 确保模块已初始化
        initialize(context)
        
        // 通过Intent启动Activity
        try {
            val intent = Intent(context, Class.forName("com.example.assistant.NotificationSettingsActivity"))
            context.startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("PushNotificationApi", "启动通知设置界面失败", e)
        }
    }
} 