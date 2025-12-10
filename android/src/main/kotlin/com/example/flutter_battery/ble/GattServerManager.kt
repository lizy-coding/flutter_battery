package com.example.flutter_battery.ble

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import com.example.flutter_battery.core.BatteryMonitor
import com.example.flutter_battery.core.TimerManager
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

class GattServerManager(
    private val context: Context,
    private val batteryMonitor: BatteryMonitor
) {

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter?
        get() = bluetoothManager.adapter

    private var gattServer: BluetoothGattServer? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var connectedDevice: BluetoothDevice? = null

    private val timerManager = TimerManager()
    private var localBatteryLevel: Int = -1
    private var remoteBatteryLevel: Int? = null

    private var peerStateListener: PeerStateListener? = null

    init {
        timerManager.setTask { refreshLocalBattery() }
    }

    fun setPeerStateListener(listener: PeerStateListener?) {
        peerStateListener = listener
    }

    fun startSlaveMode() {
        stopSlaveMode()
        val adapter = bluetoothAdapter ?: return
        if (!adapter.isEnabled) {
            return
        }
        remoteBatteryLevel = null
        gattServer = bluetoothManager.openGattServer(context, serverCallback)
        val service = createService()
        gattServer?.addService(service)
        advertiser = adapter.bluetoothLeAdvertiser
        startAdvertising()
        timerManager.setInterval(3_000)
        timerManager.start()
        refreshLocalBattery()
    }

    fun stopSlaveMode() {
        timerManager.stop()
        stopAdvertising()
        try {
            gattServer?.close()
        } catch (_: Exception) {
            // Ignore close errors
        } finally {
            gattServer = null
        }
        connectedDevice = null
        remoteBatteryLevel = null
    }

    fun updateLocalBatteryLevel(level: Int) {
        val safeLevel = level.coerceIn(0, 100)
        localBatteryLevel = safeLevel
        val characteristic = getCharacteristic(BleConstants.LOCAL_BATTERY_CHAR_UUID)
        characteristic?.value = byteArrayOf(safeLevel.toByte())
        val device = connectedDevice
        val server = gattServer
        if (device != null && server != null && characteristic != null) {
            server.notifyCharacteristicChanged(device, characteristic, false)
        }
        pushPeerState()
    }

    fun getRemoteBatteryLevel(): Int? = remoteBatteryLevel

    private fun refreshLocalBattery() {
        try {
            val level = batteryMonitor.getBatteryLevel()
            updateLocalBatteryLevel(level)
        } catch (_: Exception) {
            // Swallow exceptions to keep timer alive
        }
    }

    private fun createService(): BluetoothGattService {
        val service = BluetoothGattService(
            BleConstants.SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        val localBatteryCharacteristic = BluetoothGattCharacteristic(
            BleConstants.LOCAL_BATTERY_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        val cccDescriptor = BluetoothGattDescriptor(
            BleConstants.CLIENT_CONFIG_UUID,
            BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
        )
        localBatteryCharacteristic.addDescriptor(cccDescriptor)

        val remoteBatteryCharacteristic = BluetoothGattCharacteristic(
            BleConstants.REMOTE_BATTERY_CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_READ or BluetoothGattCharacteristic.PERMISSION_WRITE
        )

        service.addCharacteristic(localBatteryCharacteristic)
        service.addCharacteristic(remoteBatteryCharacteristic)
        return service
    }

    private fun getCharacteristic(uuid: UUID): BluetoothGattCharacteristic? {
        return gattServer?.getService(BleConstants.SERVICE_UUID)
            ?.getCharacteristic(uuid)
    }

    private fun pushPeerState() {
        val state = PeerState(
            role = "slave",
            localBattery = max(0, localBatteryLevel),
            remoteBattery = remoteBatteryLevel,
            connected = connectedDevice != null
        )
        peerStateListener?.onPeerState(state)
    }

    private fun startAdvertising() {
        val adv = advertiser ?: return
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(BleConstants.SERVICE_UUID))
            .build()

        adv.startAdvertising(settings, data, advertiseCallback)
    }

    private fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
        advertiser = null
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            when (newState) {
                android.bluetooth.BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    pushPeerState()
                }
                android.bluetooth.BluetoothProfile.STATE_DISCONNECTED -> {
                    connectedDevice = null
                    pushPeerState()
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            val value = when (characteristic.uuid) {
                BleConstants.LOCAL_BATTERY_CHAR_UUID -> {
                    byteArrayOf(localBatteryLevel.coerceIn(0, 100).toByte())
                }
                BleConstants.REMOTE_BATTERY_CHAR_UUID -> {
                    byteArrayOf((remoteBatteryLevel ?: 0).coerceIn(0, 100).toByte())
                }
                else -> null
            }
            if (value != null) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
            } else {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            if (characteristic.uuid == BleConstants.REMOTE_BATTERY_CHAR_UUID && value != null && value.isNotEmpty()) {
                val level = value[0].toInt()
                remoteBatteryLevel = min(100, max(0, level))
                characteristic.value = value
                if (responseNeeded) {
                    gattServer?.sendResponse(
                        device,
                        requestId,
                        BluetoothGatt.GATT_SUCCESS,
                        offset,
                        null
                    )
                }
                pushPeerState()
            } else {
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                }
            }
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            descriptor: BluetoothGattDescriptor
        ) {
            val value = if (descriptor.uuid == BleConstants.CLIENT_CONFIG_UUID) {
                descriptor.value ?: BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            } else {
                null
            }
            if (value != null) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
            } else {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            if (descriptor.uuid == BleConstants.CLIENT_CONFIG_UUID) {
                descriptor.value = value
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
                }
            } else if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
            }
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            pushPeerState()
        }
    }
}
