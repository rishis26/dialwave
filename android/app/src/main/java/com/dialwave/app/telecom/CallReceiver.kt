package com.dialwave.app.telecom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

/**
 * Listens for incoming phone calls and state changes on the Android device.
 * When a call is received, this broadcasts the event to the DialWaveService.
 */
class CallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            
            Log.d("DialWave", "Phone state changed: $state, number: $incomingNumber")

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    if (incomingNumber != null) {
                        // TODO: Route to CallManager/SocketManager to notify the Mac
                        Log.i("DialWave", "Incoming call from $incomingNumber")
                    }
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    Log.i("DialWave", "Call answered / dialing")
                    // Notify Mac of state change
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.i("DialWave", "Call hung up / idle")
                    // Notify Mac to hang up
                }
            }
        }
    }
}
