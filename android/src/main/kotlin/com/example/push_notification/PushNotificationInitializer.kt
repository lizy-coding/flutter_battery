package com.example.push_notification

import android.content.Context
import com.example.push_notification.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

/**
 * 推送通知模块初始化器
 * 负责初始化依赖注入和相关配置
 */
object PushNotificationInitializer {
    
    private var isInitialized = false
    
    /**
     * 初始化推送通知模块
     *
     * @param context 应用上下文
     */
    fun initialize(context: Context) {
        if (isInitialized) {
            return
        }
        
        // 初始化通知渠道
        PushNotificationManager.initNotificationChannel(context)
        
        // 初始化Koin依赖注入
        if (org.koin.core.context.GlobalContext.getOrNull() == null) {
            startKoin {
                androidContext(context)
                modules(appModule)
            }
        }
        
        isInitialized = true
        android.util.Log.d("PushNotification", "推送通知模块初始化完成")
    }
} 