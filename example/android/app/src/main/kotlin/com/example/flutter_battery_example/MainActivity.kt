package com.example.flutter_battery_example

import android.os.Bundle
import android.os.SystemClock
import com.example.flutter_battery_example.perflab.StartupTracker
import com.example.iot.nativekit.IotNativeInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "perflab"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        StartupTracker.mark("activity_onCreate")
    }

    override fun onResume() {
        super.onResume()
        StartupTracker.mark("activity_onResume")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "logMarker" -> {
                        val args = call.arguments as? Map<*, *>
                        val name = args?.get("name") as? String
                        val tMsAny = args?.get("tMs")
                        val tMs = when (tMsAny) {
                            is Number -> tMsAny.toLong()
                            else -> SystemClock.elapsedRealtime()
                        }
                        if (name.isNullOrBlank()) {
                            result.error("ARG_ERROR", "name is required", null)
                        } else {
                            StartupTracker.mark(name, tMs)
                            result.success(null)
                        }
                    }
                    "getStartupTimeline" -> {
                        result.success(StartupTracker.snapshot())
                    }
                    else -> result.notImplemented()
                }
            }

        IotNativeInitializer.attach(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        IotNativeInitializer.detach()
        super.onDestroy()
    }
}
