package com.dialwave.app.sms

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import android.util.Log

/**
 * Sends SMS messages using the Android SmsManager.
 */
class SMSSender(private val context: Context) {

    fun sendSMS(phoneNumber: String, message: String) {
        try {
            Log.i("DialWave", "Sending SMS to $phoneNumber")
            val smsManager = context.getSystemService(SmsManager::class.java)
            
            // PendingIntents could be used here to track delivery/sent status
            // For now, fire and forget
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
        } catch (e: Exception) {
            Log.e("DialWave", "Failed to send SMS", e)
        }
    }
}
