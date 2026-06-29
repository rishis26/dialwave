package com.dialwave.app.telecom

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.telecom.TelecomManager
import android.util.Log

/**
 * Interface with the Android TelecomManager to answer, reject, and dial calls.
 * Requires MANAGE_OWN_CALLS or ANSWER_PHONE_CALLS permissions.
 */
class CallManager(private val context: Context) {

    private val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager

    @SuppressLint("MissingPermission") // Permissions handled at UI layer
    fun answerCall() {
        Log.i("DialWave", "Answering call via TelecomManager")
        try {
            telecomManager.acceptRingingCall()
        } catch (e: Exception) {
            Log.e("DialWave", "Failed to answer call", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun rejectCall() {
        Log.i("DialWave", "Rejecting call via TelecomManager")
        try {
            telecomManager.endCall()
        } catch (e: Exception) {
            Log.e("DialWave", "Failed to reject call", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun dial(phoneNumber: String) {
        Log.i("DialWave", "Dialing number: $phoneNumber")
        try {
            val uri = Uri.fromParts("tel", phoneNumber, null)
            telecomManager.placeCall(uri, null)
        } catch (e: Exception) {
            Log.e("DialWave", "Failed to dial number", e)
        }
    }
    
    @SuppressLint("MissingPermission")
    fun hangup() {
        Log.i("DialWave", "Hanging up call via TelecomManager")
        try {
            telecomManager.endCall()
        } catch (e: Exception) {
            Log.e("DialWave", "Failed to hang up call", e)
        }
    }
}
