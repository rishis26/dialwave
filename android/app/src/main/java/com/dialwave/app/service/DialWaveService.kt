package com.dialwave.app.service

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.dialwave.app.App
import com.dialwave.app.R
import com.dialwave.app.bluetooth.BluetoothServer
import com.dialwave.app.ui.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job

/**
 * Foreground service that keeps DialWave alive in the background.
 * Manages BLE advertising and delegates WiFi socket work (to be implemented).
 */
class DialWaveService : Service() {

    private val serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    
    private lateinit var bluetoothServer: BluetoothServer

    override fun onCreate() {
        super.onCreate()
        
        bluetoothServer = BluetoothServer(this)
        
        bluetoothServer.onWiFiAddressReceived = { ip ->
            // TODO: Initiate WiFi socket connection to Mac's IP
            // val socketManager = WiFiSocketManager(ip)
            // socketManager.connect()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1, createNotification())
        bluetoothServer.startAdvertising()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        bluetoothServer.stopAdvertising()
        serviceJob.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, App.SERVICE_CHANNEL_ID)
            .setContentTitle("DialWave Connected")
            .setContentText("Running in background to route calls to your Mac")
            .setSmallIcon(R.mipmap.ic_launcher) // In prod, use a white silhouette icon
            .setContentIntent(pendingIntent)
            .build()
    }
}
