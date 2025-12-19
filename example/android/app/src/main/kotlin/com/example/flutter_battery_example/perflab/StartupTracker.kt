package com.example.flutter_battery_example.perflab

import android.os.SystemClock
import java.util.concurrent.ConcurrentHashMap

object StartupTracker {
    private val markers = ConcurrentHashMap<String, Long>()

    fun mark(name: String, tMs: Long = SystemClock.elapsedRealtime()) {
        // Keep first value for stability; also keep latest for debugging if needed
        markers.putIfAbsent(name, tMs)
        markers["${name}__last"] = tMs
    }

    fun get(name: String): Long = markers[name] ?: -1L

    fun snapshot(): Map<String, Any> {
        val keys = listOf(
            "app_onCreate",
            "activity_onCreate",
            "activity_onResume",
            "flutter_first_build",
            "flutter_first_frame"
        )
        val out = HashMap<String, Any>()
        for (k in keys) out[k] = get(k)

        val app = get("app_onCreate")
        val act = get("activity_onCreate")
        val res = get("activity_onResume")
        val build = get("flutter_first_build")
        val frame = get("flutter_first_frame")

        fun delta(a: Long, b: Long): Long = if (a <= 0 || b <= 0) -1L else (b - a)

        out["d_app_to_activity"] = delta(app, act)
        out["d_activity_to_resume"] = delta(act, res)
        out["d_app_to_flutter_first_build"] = delta(app, build)
        out["d_app_to_flutter_first_frame"] = delta(app, frame)
        out["note"] = "All timestamps are SystemClock.elapsedRealtime() ms. Flutter markers are reported from Dart via MethodChannel."
        return out
    }
}
