package com.example.flutter_battery_example

import com.example.iot.nativekit.IotNativeInitializer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        IotNativeInitializer.attach(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        IotNativeInitializer.detach()
        super.onDestroy()
    }
}
