package com.example.push_notification.push_notification

//noinspection SuspiciousImport
import android.R
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        // 将新令牌发送到服务器
        sendRegistrationToServer(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // 处理接收到的消息
        remoteMessage.notification?.let {
            sendNotification(it)
        }
    }

    private fun sendRegistrationToServer(token: String) {
        // 实现将令牌发送到服务器的逻辑
    }

    private fun sendNotification(notification: RemoteMessage.Notification) {
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        // 创建通知渠道（仅适用于Android 8.0及以上）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "default",
                "Channel human readable title",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        // 构建通知
        val notificationBuilder = NotificationCompat.Builder(this, "default")
            .setContentTitle(notification.title)
            .setContentText(notification.body)
            .setSmallIcon(R.drawable.ic_dialog_info)
            .setAutoCancel(true)

        // 显示通知
        notificationManager.notify(0, notificationBuilder.build())
    }
}