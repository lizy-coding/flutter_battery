package com.example.push_notification.data.repository

import com.example.push_notification.data.model.NotificationData

class NotificationRepository {
    private val notifications = mutableListOf<NotificationData>()

    fun addNotification(notification: NotificationData) {
        notifications.add(notification)
    }

    fun getNotifications(): List<NotificationData> {
        return notifications
    }
}