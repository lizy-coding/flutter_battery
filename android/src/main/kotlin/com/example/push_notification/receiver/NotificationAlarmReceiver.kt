package com.example.push_notification.receiver

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.push_notification.PushNotificationManager
import com.example.push_notification.util.Constants

/**
 * 通知闹钟接收器
 * 用于接收定时闹钟广播并显示推送通知
 */
class NotificationAlarmReceiver : BroadcastReceiver() {

    @SuppressLint("LongLogTag")
    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d("NotificationAlarmReceiver", "接收到通知闹钟广播")

        // 从Intent中提取通知数据
        val title = intent.getStringExtra(Constants.EXTRA_NOTIFICATION_TITLE) ?: "推送通知"
        val message = intent.getStringExtra(Constants.EXTRA_NOTIFICATION_MESSAGE) ?: "您有一条新消息"
        val notificationId = intent.getIntExtra(Constants.EXTRA_NOTIFICATION_ID, System.currentTimeMillis().toInt())

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