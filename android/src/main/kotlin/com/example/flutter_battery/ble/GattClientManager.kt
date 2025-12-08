package com.example.flutter_battery.ble

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.TimerManager
import kotlin.math.max
import kotlin.math.min

class GattClientManager(
    private val context: Context,
    private val batteryMonitor: BatteryMonitor,
    private val bleManager: BleManager? = null
) {

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter?
        get() = bluetoothManager.adapter

    private val mainHandler = Handler(Looper.getMainLooper())

    private var bluetoothGatt: BluetoothGatt? = null
    private var currentDeviceId: String? = null
    private var isConnected: Boolean = false

    private var localBatteryLevel: Int = -1
    private var remoteBatteryLevel: Int? = null

    private var localBatteryCharacteristic: BluetoothGattCharacteristic? = null
    private var remoteBatteryCharacteristic: BluetoothGattCharacteristic? = null

    private val pushTimer = TimerManager()

    private var peerStateListener: PeerStateListener? = null

    init {
        pushTimer.setTask { pushLocalBatteryToRemote() }
    }

    fun startMasterMode() {
        stopMasterMode()
        localBatteryLevel = try {
            batteryMonitor.getBatteryLevel()
        } catch (_: Exception) {
            localBatteryLevel
        }.coerceIn(0, 100)
        pushPeerState()
        startScanForSlave()
    }

    fun setPeerStateListener(listener: PeerStateListener?) {
        peerStateListener = listener
    }

    fun startScanForSlave() {
        bleManager?.startScan(BleConstants.SERVICE_UUID.toString())
    }

    fun stopScan() {
        bleManager?.stopScan()
    }

    fun connectToSlave(deviceId: String) {
        val adapter = bluetoothAdapter ?: return
        val device: BluetoothDevice = try {
            adapter.getRemoteDevice(deviceId)
        } catch (_: IllegalArgumentException) {
            pushPeerState()
            return
        }
        stopScan()
        disconnect()
        currentDeviceId = device.address
        mainHandler.post {
            bluetoothGatt = device.connectGatt(context, false, gattCallback)
            pushPeerState()
        }
    }

    fun disconnect() {
        pushTimer.stop()
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
        isConnected = false
        remoteBatteryLevel = null
        localBatteryCharacteristic = null
        remoteBatteryCharacteristic = null
        currentDeviceId = null
        pushPeerState()
    }

    fun stopMasterMode() {
        stopScan()
        disconnect()
    }

    private fun pushLocalBatteryToRemote() {
        val gatt = bluetoothGatt ?: return
        val characteristic = remoteBatteryCharacteristic ?: return
        val level = try {
            batteryMonitor.getBatteryLevel()
        } catch (_: Exception) {
            localBatteryLevel
        }.coerceIn(0, 100)
        localBatteryLevel = level
        val payload = byteArrayOf(level.toByte())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeCharacteristic(
                characteristic,
                payload,
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            )
        } else {
            @Suppress("DEPRECATION")
            run {
                characteristic.value = payload
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                gatt.writeCharacteristic(characteristic)
            }
        }
        pushPeerState()
    }

    private fun enableNotification(characteristic: BluetoothGattCharacteristic?) {
        val gatt = bluetoothGatt ?: return
        if (characteristic == null) return
        gatt.setCharacteristicNotification(characteristic, true)
        val descriptor = characteristic.getDescriptor(BleConstants.CLIENT_CONFIG_UUID)
        if (descriptor != null) {
            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            gatt.writeDescriptor(descriptor)
        }
    }

    private fun pushPeerState() {
        val state = PeerState(
            role = "master",
            localBattery = max(0, localBatteryLevel),
            remoteBattery = remoteBatteryLevel,
            connected = isConnected
        )
        peerStateListener?.onPeerState(state)
    }

    private fun readSlaveBattery() {
        val characteristic = localBatteryCharacteristic ?: return
        bluetoothGatt?.readCharacteristic(characteristic)
    }

    private fun onSlaveBattery(level: Int) {
        remoteBatteryLevel = min(100, max(0, level))
        pushPeerState()
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                isConnected = false
                pushTimer.stop()
                pushPeerState()
                bluetoothGatt?.close()
                bluetoothGatt = null
                return
            }
            when (newState) {
                android.bluetooth.BluetoothProfile.STATE_CONNECTED -> {
                    isConnected = true
                    pushPeerState()
                    gatt.discoverServices()
                }
                android.bluetooth.BluetoothProfile.STATE_DISCONNECTED -> {
                    isConnected = false
                    pushTimer.stop()
                    pushPeerState()
                    bluetoothGatt?.close()
                    bluetoothGatt = null
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                return
            }
            val service: BluetoothGattService? = gatt.getService(BleConstants.SERVICE_UUID)
            localBatteryCharacteristic = service?.getCharacteristic(BleConstants.LOCAL_BATTERY_CHAR_UUID)
            remoteBatteryCharacteristic = service?.getCharacteristic(BleConstants.REMOTE_BATTERY_CHAR_UUID)
            if (localBatteryCharacteristic != null) {
                enableNotification(localBatteryCharacteristic)
                readSlaveBattery()
            }
            if (remoteBatteryCharacteristic != null) {
                pushTimer.setInterval(3_000)
                pushTimer.start()
            }
            pushPeerState()
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (characteristic.uuid == BleConstants.LOCAL_BATTERY_CHAR_UUID) {
                val value = characteristic.value
                if (value != null && value.isNotEmpty()) {
                    onSlaveBattery(value[0].toInt())
                }
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            if (characteristic.uuid == BleConstants.LOCAL_BATTERY_CHAR_UUID) {
                val value = characteristic.value
                if (value != null && value.isNotEmpty()) {
                    onSlaveBattery(value[0].toInt())
                }
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int
        ) {
            if (descriptor.uuid == BleConstants.CLIENT_CONFIG_UUID) {
                readSlaveBattery()
            }
        }
    }
}
