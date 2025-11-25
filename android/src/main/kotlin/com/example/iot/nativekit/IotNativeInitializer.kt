package com.example.iot.nativekit

import android.content.Context
import android.util.Log
import com.example.iot.nativekit.data.ble.BleRepositoryImpl
import com.example.iot.nativekit.data.power.PowerRepositoryImpl
import com.example.iot.nativekit.data.telemetry.TelemetryRepository
import com.example.iot.nativekit.data.telemetry.TelemetryRepositoryImpl
import com.example.iot.nativekit.platform.Channels
import com.example.iot.nativekit.platform.NativeRepositoryHolder
import com.example.iot.nativekit.presentation.NativeViewModel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger

/**
 * IoT 原生初始化器
 *
 * 负责向 FlutterEngine 附加/拆卸原生 Channels 与 ViewModel，并注册数据仓库。
 * 提供一次性初始化入口，保证幂等与线程安全。
 *
 * 版本：v1（与 Channels 的 METHOD_CHANNEL/EVENT_CHANNEL 保持兼容）。
 */
object IotNativeInitializer {

    @Volatile
    private var channels: Channels? = null
    @Volatile
    private var viewModel: NativeViewModel? = null

    fun attach(flutterEngine: FlutterEngine, context: Context) {
        attach(context, flutterEngine.dartExecutor.binaryMessenger)
    }

    fun attach(context: Context, messenger: BinaryMessenger) {
        if (channels != null) {
            Log.d(TAG, "Already attached, ignoring.")
            return
        }
        val telemetryRepository: TelemetryRepository = TelemetryRepositoryImpl()
        val bleRepository = BleRepositoryImpl()
        val powerRepository = PowerRepositoryImpl()
        NativeRepositoryHolder.registerTelemetry(telemetryRepository)
        val vm = NativeViewModel(
            bleRepository = bleRepository,
            telemetryRepository = telemetryRepository,
            powerRepository = powerRepository
        )
        viewModel = vm
        channels = Channels(
            appContext = context.applicationContext,
            messenger = messenger,
            viewModel = vm
        )
        Log.d(TAG, "IoT native channels attached.")
    }

    fun detach() {
        channels?.dispose()
        channels = null
        viewModel?.clear()
        viewModel = null
        NativeRepositoryHolder.clear()
    }

    private const val TAG = "IotNativeInitializer"
}
