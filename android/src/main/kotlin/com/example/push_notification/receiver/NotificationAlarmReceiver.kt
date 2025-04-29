package com.example.push_notification.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.push_notification.PushNotificationManager
import com.example.push_notification.data.model.NotificationData
import com.example.push_notification.data.repository.NotificationRepository
import com.example.push_notification.util.Constants
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

/**
 * 通知闹钟接收器
 * 用于接收定时闹钟广播并显示推送通知
 */
class NotificationAlarmReceiver : BroadcastReceiver(), KoinComponent {

    private val notificationRepository: NotificationRepository by inject()

    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d("NotificationAlarmReceiver", "接收到通知闹钟广播")

        // 从Intent中提取通知数据
        val title = intent.getStringExtra(Constants.EXTRA_NOTIFICATION_TITLE) ?: "推送通知"
        val message = intent.getStringExtra(Constants.EXTRA_NOTIFICATION_MESSAGE) ?: "您有一条新消息"
        val notificationId = intent.getIntExtra(Constants.EXTRA_NOTIFICATION_ID, System.currentTimeMillis().toInt())

        // 临时创建一个仓库实例，避免依赖注入失败
        val repository = try {
            notificationRepository
        } catch (e: Exception) {
            NotificationRepository()
        }

        // 保存通知到数据库
        val notificationData = NotificationData(
            id = notificationId.toString(),
            title = title,
            message = message,
            timestamp = System.currentTimeMillis()
        )
        try {
            repository.addNotification(notificationData)
            android.util.Log.d("NotificationAlarmReceiver", "通知已保存: $notificationData")
        } catch (e: Exception) {
            android.util.Log.e("NotificationAlarmReceiver", "保存通知失败: ${e.message}")
        }

        // 显示通知
        PushNotificationManager.showNotification(
            context = context,
            title = title,
            message = message,
            notificationId = notificationId
        )
        android.util.Log.d("NotificationAlarmReceiver", "通知已显示，ID: $notificationId")
    }
} 