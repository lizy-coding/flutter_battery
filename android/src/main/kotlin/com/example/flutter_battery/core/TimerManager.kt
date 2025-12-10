package com.example.flutter_battery.core

import android.os.Handler
import android.os.Looper
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.atomic.AtomicBoolean

/**
 * 通用定时器管理器
 * 管理定时任务，支持定时间隔和任务取消
 */
class TimerManager {
    // 定时器
    private var timer: Timer? = null
    
    // 定时任务配置
    private var intervalMs: Long = 1000
    private var taskAction: (() -> Unit)? = null
    private val isRunning = AtomicBoolean(false)
    
    // 防止并发问题的锁对象
    private val lock = Any()
    
    /**
     * 设置任务间隔
     * @param intervalMs 定时间隔（毫秒）
     */
    fun setInterval(intervalMs: Long) {
        synchronized(lock) {
            this.intervalMs = intervalMs
            
            // 如果定时器已在运行，则重启应用新的间隔
            if (isRunning.get()) {
                stop()
                start()
            }
        }
    }
    
    /**
     * 设置定时执行的任务
     * @param action 要执行的任务
     */
    fun setTask(action: () -> Unit) {
        synchronized(lock) {
            this.taskAction = action
        }
    }
    
    /**
     * 启动定时器
     * @param initialDelayMs 初始延迟（毫秒）
     * @return 是否成功启动
     */
    fun start(initialDelayMs: Long = 0): Boolean {
        synchronized(lock) {
            if (taskAction == null) {
                return false
            }
            
            try {
                stop()
                
                timer = Timer()
                timer?.schedule(object : TimerTask() {
                    override fun run() {
                        Handler(Looper.getMainLooper()).post {
                            try {
                                taskAction?.invoke()
                            } catch (e: Exception) {
                                android.util.Log.e("TimerManager", "Error executing timer task: ${e.message}")
                            }
                        }
                    }
                }, initialDelayMs, intervalMs)
                
                isRunning.set(true)
                return true
            } catch (e: Exception) {
                android.util.Log.e("TimerManager", "Error starting timer: ${e.message}")
                isRunning.set(false)
                return false
            }
        }
    }
    
    /**
     * 停止定时器
     */
    fun stop() {
        synchronized(lock) {
            try {
                timer?.cancel()
                timer = null
                isRunning.set(false)
            } catch (e: Exception) {
                android.util.Log.e("TimerManager", "Error stopping timer: ${e.message}")
            }
        }
    }
    
    /**
     * 检查定时器是否在运行
     * @return 是否在运行
     */
    fun isRunning(): Boolean {
        return isRunning.get()
    }
    
    /**
     * 清理资源
     */
    fun dispose() {
        synchronized(lock) {
            try {
                stop()
                taskAction = null
            } catch (e: Exception) {
                android.util.Log.e("TimerManager", "Error disposing timer: ${e.message}")
            }
        }
    }
} 