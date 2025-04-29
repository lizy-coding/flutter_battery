package com.example.flutter_assistant

import androidx.annotation.NonNull
import com.example.push_notification.PushNotificationManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterAssistantPlugin */
class FlutterAssistantPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: android.content.Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_assistant")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "scheduleNotification" -> {
                try {
                    val title = call.argument<String>("title") ?: "通知"
                    val message = call.argument<String>("message") ?: "您有一条新消息"
                    val delayMinutes = call.argument<Int>("delayMinutes") ?: 1

                    PushNotificationManager.scheduleNotification(
                        applicationContext,
                        title,
                        message,
                        delayMinutes
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", "无法调度通知: ${e.message}", null)
                }
            }
            "showNotification" -> {
                try {
                    val title = call.argument<String>("title") ?: "通知"
                    val message = call.argument<String>("message") ?: "您有一条新消息"

                    PushNotificationManager.showNotification(
                        applicationContext,
                        title,
                        message
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", "无法显示通知: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
} 