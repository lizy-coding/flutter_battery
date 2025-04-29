package com.example.push_notification.di

import com.example.push_notification.data.repository.NotificationRepository
import org.koin.dsl.module

/**
 * 应用程序依赖注入模块
 */
val appModule = module {
    // 单例模式提供NotificationRepository
    single { NotificationRepository() }
}