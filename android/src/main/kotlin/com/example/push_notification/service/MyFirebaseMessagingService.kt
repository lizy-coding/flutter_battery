package com.example.push_notification.service

import android.annotation.SuppressLint
import com.example.push_notification.data.model.NotificationData
import com.example.push_notification.data.repository.NotificationRepository
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@SuppressLint("MissingFirebaseInstanceTokenRefresh")
class MyFirebaseMessagingService : FirebaseMessagingService(), KoinComponent {
    private val notificationRepository: NotificationRepository by inject()

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        remoteMessage.notification?.let { notification ->
            val notificationData = NotificationData(
                id = remoteMessage.messageId ?: "",
                title = notification.title ?: "",
                message = notification.body ?: "",
                timestamp = System.currentTimeMillis()
            )
            
            try {
                notificationRepository.addNotification(notificationData)
            } catch (e: Exception) {
                android.util.Log.e("FirebaseMessaging", "保存通知失败: ${e.message}")
                // 失败时尝试创建新的实例
                try {
                    NotificationRepository().addNotification(notificationData)
                } catch (e: Exception) {
                    android.util.Log.e("FirebaseMessaging", "备用保存也失败: ${e.message}")
                }
            }
        }
    }
}