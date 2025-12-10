package com.example.iot.nativekit.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.iot.nativekit.domain.model.Telemetry
import com.example.iot.nativekit.platform.NativeRepositoryHolder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.plus
import kotlin.random.Random

class SyncService : Service() {

    private val scope = CoroutineScope(SupervisorJob()).plus(Dispatchers.Default)
    private val random = Random(System.currentTimeMillis())
    private var emitterJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "SyncService onStartCommand")
        startForeground(NOTIFICATION_ID, buildNotification())
        if (emitterJob?.isActive == true) return START_STICKY
        emitterJob = scope.launch {
            while (isActive) {
                val telemetry = Telemetry(
                    timestamp = System.currentTimeMillis(),
                    speed = random.nextDouble(10.0, 35.0),
                    batteryPct = random.nextInt(30, 95)
                )
                val repository = NativeRepositoryHolder.provideTelemetry()
                if (repository == null) {
                    Log.w(TAG, "TelemetryRepository missing, skipping emission.")
                } else {
                    repository.publish(telemetry)
                }
                delay(2_000L)
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "SyncService destroyed")
        emitterJob?.cancel()
        emitterJob = null
        scope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val pending = PendingIntent.getActivity(
            this,
            0,
            Intent(),
            PendingIntent.FLAG_IMMUTABLE
        )
        val label = applicationInfo.loadLabel(packageManager).toString()
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(label)
            .setContentText("IoT Sync Service running")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentIntent(pending)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "IoT Sync",
            NotificationManager.IMPORTANCE_LOW
        )
        channel.description = "Keep the IoT sync loop alive"
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val TAG = "SyncService"
        private const val CHANNEL_ID = "iot-sync"
        private const val NOTIFICATION_ID = 201

        fun start(context: Context) {
            val appContext = context.applicationContext
            val intent = Intent(appContext, SyncService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appContext.startForegroundService(intent)
            } else {
                appContext.startService(intent)
            }
        }

        fun stop(context: Context) {
            val appContext = context.applicationContext
            val intent = Intent(appContext, SyncService::class.java)
            appContext.stopService(intent)
        }
    }
}
