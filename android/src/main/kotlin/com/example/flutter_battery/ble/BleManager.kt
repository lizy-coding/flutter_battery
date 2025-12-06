package com.example.flutter_battery.ble

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.UUID

class BleManager(private val context: Context) {

    interface ScanListener {
        fun onDeviceFound(device: BleDevice)
        fun onScanError(message: String)
    }

    interface ConnectionListener {
        fun onConnectionEvent(event: BleConnectionEvent)
    }

    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter?
        get() = bluetoothManager.adapter

    private var scanListener: ScanListener? = null
    private var connectionListener: ConnectionListener? = null

    private var scanning: Boolean = false
    private var bluetoothLeScanner: BluetoothLeScanner? = null

    private var currentGatt: BluetoothGatt? = null
    private var currentDeviceId: String? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val id = device.address ?: return
            val name = device.name ?: ""
            val rssi = result.rssi
            val bleDevice = BleDevice(id = id, name = name, rssi = rssi)
            scanListener?.onDeviceFound(bleDevice)
        }

        override fun onScanFailed(errorCode: Int) {
            scanListener?.onScanError("Scan failed with error code: $errorCode")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val deviceId = gatt.device.address ?: ""
            when (newState) {
                android.bluetooth.BluetoothProfile.STATE_CONNECTING -> {
                    connectionListener?.onConnectionEvent(
                        BleConnectionEvent(BleConnectionState.CONNECTING, deviceId, null)
                    )
                }
                android.bluetooth.BluetoothProfile.STATE_CONNECTED -> {
                    currentGatt = gatt
                    currentDeviceId = deviceId
                    connectionListener?.onConnectionEvent(
                        BleConnectionEvent(BleConnectionState.CONNECTED, deviceId, null)
                    )
                    gatt.discoverServices()
                }
                android.bluetooth.BluetoothProfile.STATE_DISCONNECTING -> {
                    connectionListener?.onConnectionEvent(
                        BleConnectionEvent(BleConnectionState.DISCONNECTING, deviceId, null)
                    )
                }
                android.bluetooth.BluetoothProfile.STATE_DISCONNECTED -> {
                    currentGatt?.close()
                    currentGatt = null
                    currentDeviceId = null
                    connectionListener?.onConnectionEvent(
                        BleConnectionEvent(BleConnectionState.DISCONNECTED, deviceId, null)
                    )
                }
            }
        }
    }

    fun isBleAvailable(): Boolean {
        return bluetoothAdapter != null
    }

    fun isBleEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    fun setScanListener(listener: ScanListener?) {
        scanListener = listener
    }

    fun setConnectionListener(listener: ConnectionListener?) {
        connectionListener = listener
    }

    fun startScan(serviceUuid: String?) {
        val adapter = bluetoothAdapter
        if (adapter == null) {
            scanListener?.onScanError("Bluetooth adapter not available")
            return
        }
        if (!adapter.isEnabled) {
            scanListener?.onScanError("Bluetooth is disabled")
            return
        }
        if (scanning) return

        bluetoothLeScanner = adapter.bluetoothLeScanner
        val scanner = bluetoothLeScanner
        if (scanner == null) {
            scanListener?.onScanError("BluetoothLeScanner not available")
            return
        }

        val filters = mutableListOf<ScanFilter>()
        if (!serviceUuid.isNullOrEmpty()) {
            val uuid = try {
                UUID.fromString(serviceUuid)
            } catch (e: IllegalArgumentException) {
                null
            }
            if (uuid != null) {
                filters.add(
                    ScanFilter.Builder()
                        .setServiceUuid(android.os.ParcelUuid(uuid))
                        .build()
                )
            }
        }

        val settingsBuilder = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            settingsBuilder.setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
        }
        val settings = settingsBuilder.build()

        scanning = true
        scanner.startScan(filters, settings, scanCallback)
    }

    fun stopScan() {
        if (!scanning) return
        val scanner = bluetoothLeScanner ?: return
        scanning = false
        scanner.stopScan(scanCallback)
    }

    fun connect(deviceId: String, autoConnect: Boolean) {
        val adapter = bluetoothAdapter ?: return
        val device: BluetoothDevice = try {
            adapter.getRemoteDevice(deviceId)
        } catch (e: IllegalArgumentException) {
            connectionListener?.onConnectionEvent(
                BleConnectionEvent(
                    BleConnectionState.DISCONNECTED,
                    deviceId,
                    "Invalid device address"
                )
            )
            return
        }

        currentGatt?.close()
        currentGatt = null
        currentDeviceId = null

        mainHandler.post {
            val gatt = device.connectGatt(context, autoConnect, gattCallback)
            if (gatt == null) {
                connectionListener?.onConnectionEvent(
                    BleConnectionEvent(
                        BleConnectionState.DISCONNECTED,
                        deviceId,
                        "Failed to connect GATT"
                    )
                )
            } else {
                currentGatt = gatt
                currentDeviceId = deviceId
                connectionListener?.onConnectionEvent(
                    BleConnectionEvent(BleConnectionState.CONNECTING, deviceId, null)
                )
            }
        }
    }

    fun disconnect(deviceId: String?) {
        val currentId = currentDeviceId
        if (currentId == null) {
            return
        }
        if (deviceId != null && deviceId != currentId) {
            return
        }
        val gatt = currentGatt ?: return
        mainHandler.post {
            gatt.disconnect()
            gatt.close()
            currentGatt = null
            currentDeviceId = null
            connectionListener?.onConnectionEvent(
                BleConnectionEvent(BleConnectionState.DISCONNECTED, currentId, null)
            )
        }
    }

    fun writeCharacteristic(
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        value: ByteArray,
        withResponse: Boolean
    ): Boolean {
        val gatt = currentGatt ?: return false
        val currentId = currentDeviceId
        if (currentId == null || currentId != deviceId) {
            return false
        }
        val service: BluetoothGattService = try {
            gatt.getService(UUID.fromString(serviceUuid))
        } catch (e: IllegalArgumentException) {
            return false
        } ?: return false

        val characteristic: BluetoothGattCharacteristic = try {
            service.getCharacteristic(UUID.fromString(characteristicUuid))
        } catch (e: IllegalArgumentException) {
            return false
        } ?: return false

        characteristic.value = value
        characteristic.writeType = if (withResponse) {
            BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        } else {
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        }
        return gatt.writeCharacteristic(characteristic)
    }
}
