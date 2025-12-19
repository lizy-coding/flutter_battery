package com.example.flutter_battery_example

import android.app.Application
import com.example.flutter_battery_example.perflab.StartupTracker

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        StartupTracker.mark("app_onCreate")
    }
}
