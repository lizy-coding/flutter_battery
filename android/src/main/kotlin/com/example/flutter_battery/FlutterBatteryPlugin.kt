package com.example.flutter_battery

import android.content.Context
import androidx.annotation.NonNull
import com.example.flutter_battery.channel.EventChannelHandler
import com.example.flutter_battery.channel.MethodChannelHandler
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.NotificationHelper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** FlutterBatteryPlugin */
class FlutterBatteryPlugin : FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context
    private var activity: android.app.Activity? = null
    
    // 核心组件
    private lateinit var batteryMonitor: BatteryMonitor
    private lateinit var notificationHelper: NotificationHelper
    
    // 通道处理器
    private lateinit var methodChannelHandler: MethodChannelHandler
    private lateinit var eventChannelHandler: EventChannelHandler
    
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // 1. 初始化通道
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_battery")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_battery/battery_stream")
        applicationContext = flutterPluginBinding.applicationContext
        
        // 2. 初始化核心组件
        batteryMonitor = BatteryMonitor(applicationContext)
        notificationHelper = NotificationHelper(applicationContext)
        
        // 3. 初始化通道处理器
        methodChannelHandler = MethodChannelHandler(
            applicationContext,
            methodChannel,
            batteryMonitor,
            notificationHelper
        )
        
        eventChannelHandler = EventChannelHandler(
            applicationContext,
            eventChannel,
            batteryMonitor
        )
        
        // 设置关联，让 MethodChannelHandler 可以访问 EventChannelHandler
        methodChannelHandler.setEventChannelHandler(eventChannelHandler)
        
        // 4. 设置方法调用处理器
        methodChannel.setMethodCallHandler(methodChannelHandler)
        
        // 5. 设置权限结果处理器
        notificationHelper.setPermissionResultListener { requestCode, permissions, grantResults ->
            onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // 释放资源
        methodChannel.setMethodCallHandler(null)
        batteryMonitor.dispose()
        notificationHelper.dispose()
        methodChannelHandler.dispose()
        eventChannelHandler.dispose()
    }
    
    // ActivityAware接口实现
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        methodChannelHandler.setActivity(activity)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        methodChannelHandler.setActivity(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        methodChannelHandler.setActivity(activity)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
        methodChannelHandler.setActivity(null)
    }
    
    // 权限请求结果回调
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        return notificationHelper.handleRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}