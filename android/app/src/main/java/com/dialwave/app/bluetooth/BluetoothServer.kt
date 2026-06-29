package com.dialwave.app.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.util.UUID

@SuppressLint("MissingPermission") // Permissions checked at UI layer
class BluetoothServer(private val context: Context) {

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val adapter = bluetoothManager.adapter
    private val advertiser = adapter.bluetoothLeAdvertiser
    
    private var gattServer: BluetoothGattServer? = null
    
    // UUIDs matching Mac exactly
    private val serviceUuid = UUID.fromString("0000181A-0000-1000-8000-00805F9B34FB") // Env Sensing for demo, use custom in prod
    private val rxCharacteristicUuid = UUID.fromString("00002A6E-0000-1000-8000-00805F9B34FB")

    private val _state = MutableStateFlow(ConnectionState.DISCONNECTED)
    val state: StateFlow<ConnectionState> = _state

    var onWiFiAddressReceived: ((String) -> Unit)? = null

    fun startAdvertising() {
        if (!adapter.isEnabled) return
        
        setupGattServer()
        
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
            
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(serviceUuid))
            .build()
            
        advertiser?.startAdvertising(settings, data, advertiseCallback)
        _state.value = ConnectionState.ADVERTISING
        Log.d("DialWave", "Started BLE Advertising")
    }
    
    fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
        gattServer?.close()
        gattServer = null
        _state.value = ConnectionState.DISCONNECTED
    }

    private fun setupGattServer() {
        gattServer = bluetoothManager.openGattServer(context, gattServerCallback)
        
        val service = BluetoothGattService(serviceUuid, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val rxChar = BluetoothGattCharacteristic(
            rxCharacteristicUuid,
            BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        
        service.addCharacteristic(rxChar)
        gattServer?.addService(service)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.d("DialWave", "Advertising successfully started")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e("DialWave", "Advertising failed: $errorCode")
            _state.value = ConnectionState.ERROR
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                Log.d("DialWave", "Mac connected via BLE")
                _state.value = ConnectionState.WAITING_FOR_WIFI
            } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                Log.d("DialWave", "Mac disconnected from BLE")
                if (_state.value == ConnectionState.WAITING_FOR_WIFI) {
                    _state.value = ConnectionState.ADVERTISING
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray
        ) {
            if (characteristic.uuid == rxCharacteristicUuid) {
                val ipAddress = String(value, Charsets.UTF_8)
                Log.d("DialWave", "Received Mac IP via BLE: $ipAddress")
                
                if (responseNeeded) {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                }
                
                onWiFiAddressReceived?.invoke(ipAddress)
            }
        }
    }
}
