package com.example.iot.nativekit.platform

import com.example.iot.nativekit.data.telemetry.TelemetryRepository

internal object NativeRepositoryHolder {
    @Volatile
    private var telemetryRepository: TelemetryRepository? = null

    fun registerTelemetry(repository: TelemetryRepository) {
        telemetryRepository = repository
    }

    fun provideTelemetry(): TelemetryRepository? = telemetryRepository

    fun clear() {
        telemetryRepository = null
    }
}
