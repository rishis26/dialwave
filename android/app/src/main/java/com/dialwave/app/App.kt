package com.dialwave.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

class App : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                SERVICE_CHANNEL_ID,
                "DialWave Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps DialWave running in the background to handle calls from your Mac"
                setShowBadge(false)
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(serviceChannel)
        }
    }

    companion object {
        const val SERVICE_CHANNEL_ID = "DialWaveServiceChannel"
    }
}
