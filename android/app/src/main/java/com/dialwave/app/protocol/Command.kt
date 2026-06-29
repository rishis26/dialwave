package com.dialwave.app.protocol

import kotlinx.serialization.Serializable

// MARK: - Commands (Mac -> Android)

@Serializable
data class CallControlCommand(
    val callId: String,
    val action: String // "answer", "reject", "hangup"
)

@Serializable
data class DialCommand(
    val phoneNumber: String,
    val contactName: String? = null
)

@Serializable
data class SMSCommand(
    val recipientNumber: String,
    val body: String,
    val threadId: String? = null
)
