package com.example.push_notification.presentation.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.example.push_notification.data.model.NotificationData
import com.example.push_notification.domain.usecase.GetNotificationUseCase


class MainViewModel(private val getNotificationUseCase: GetNotificationUseCase) : ViewModel() {
    private val _notifications = MutableLiveData<List<NotificationData>>()
    val notifications: LiveData<List<NotificationData>> get() = _notifications

    fun loadNotifications() {
        _notifications.value = getNotificationUseCase()
    }
}