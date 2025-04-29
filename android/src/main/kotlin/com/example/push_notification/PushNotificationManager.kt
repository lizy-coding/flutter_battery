package com.example.push_notification

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.push_notification.receiver.NotificationAlarmReceiver
import com.example.push_notification.util.Constants

/**
 * 推送通知管理器
 * 提供延迟推送通知和通知管理功能
 */
object PushNotificationManager {

    private const val NOTIFICATION_CHANNEL_ID = "delayed_notifications"
    private const val NOTIFICATION_CHANNEL_NAME = "延迟推送通知"
    private const val NOTIFICATION_CHANNEL_DESCRIPTION = "用于显示延迟推送的通知"

    /**
     * 初始化通知渠道（Android 8.0及以上需要）
     *
     * @param context 上下文
     */
    fun initNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = NOTIFICATION_CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * 调度一个延迟推送通知
     *
     * @param context 上下文
     * @param title 通知标题
     * @param message 通知内容
     * @param delayMinutes 延迟分钟数（默认1分钟）
     */
    fun scheduleNotification(
        context: Context,
        title: String,
        message: String,
        delayMinutes: Int = 1
    ) {
        // 确保通知渠道已初始化
        initNotificationChannel(context)

        // 创建通知内容Intent
        val notificationIntent = Intent(context, NotificationAlarmReceiver::class.java).apply {
            putExtra(Constants.EXTRA_NOTIFICATION_TITLE, title)
            putExtra(Constants.EXTRA_NOTIFICATION_MESSAGE, message)
        }

        // 创建唯一的请求码，避免PendingIntent覆盖
        val requestCode = System.currentTimeMillis().toInt()

        // 创建PendingIntent
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 获取AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // 计算触发时间
        val triggerTimeMillis = System.currentTimeMillis() + (delayMinutes * 60 * 1000)

        // 设置定时器
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerTimeMillis,
            pendingIntent
        )

        // 记录日志
        android.util.Log.d("PushNotification", "已设置延迟通知，将在${delayMinutes}分钟后（${triggerTimeMillis}时间点）发送")
    }

    /**
     * 显示一个通知
     *
     * @param context 上下文
     * @param title 通知标题
     * @param message 通知内容
     * @param notificationId 通知ID
     */
    fun showNotification(
        context: Context,
        title: String,
        message: String,
        notificationId: Int = System.currentTimeMillis().toInt()
    ) {
        // 确保通知渠道已初始化
        initNotificationChannel(context)

        // 创建通知构建器
        val notificationBuilder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // 使用系统图标作为占位符
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)

        // 获取通知管理器并显示通知
        val notificationManager = ContextCompat.getSystemService(context, NotificationManager::class.java)
        notificationManager?.notify(notificationId, notificationBuilder.build())
    }
} 