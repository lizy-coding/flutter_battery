package com.example.flutter_battery_example

import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import com.example.flutter_battery_example.perflab.StartupTracker
import com.example.iot.nativekit.IotNativeInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "perflab"
    private var splashHidden = false

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

        IotNativeInitializer.setMarker { name -> StartupTracker.mark(name) }

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
                    "hideSplash" -> {
                        hideSplash()
                        result.success(null)
                    }
                    "isSplashVisible" -> {
                        result.success(!splashHidden)
                    }
                    "iotWarmup" -> {
                        IotNativeInitializer.warmupAsync()
                        result.success(null)
                    }
                    "getStartupTimeline" -> {
                        result.success(StartupTracker.snapshot())
                    }
                    else -> result.notImplemented()
                }
            }

        val attachEnter = SystemClock.elapsedRealtime()
        StartupTracker.mark("iot_attach_enter", attachEnter)
        IotNativeInitializer.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        val attachExit = SystemClock.elapsedRealtime()
        StartupTracker.mark("iot_attach_exit", attachExit)
        Log.d("PerfLab", "iot_attach duration=${attachExit - attachEnter}ms")
    }

    override fun onDestroy() {
        IotNativeInitializer.detach()
        super.onDestroy()
    }

    private fun hideSplash() {
        if (splashHidden) return
        splashHidden = true
        runCatching {
            setTheme(R.style.NormalTheme)
            window.setBackgroundDrawableResource(android.R.color.transparent)
        }
    }
}
