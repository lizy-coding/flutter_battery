package com.example.push_notification.domain.usecase

import com.example.push_notification.data.model.NotificationData
import com.example.push_notification.data.repository.NotificationRepository


class GetNotificationUseCase(private val repository: NotificationRepository) {
    operator fun invoke(): List<NotificationData> {
        return repository.getNotifications()
    }
}